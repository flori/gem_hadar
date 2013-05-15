require 'rubygems'
require 'rbconfig'
if defined?(::RbConfig)
  include ::RbConfig
else
  include ::Config
end
require 'rake'
require 'tins/xt'
require 'tins/secure_write'
require 'rake/clean'
require 'rake/testtask'
require 'dslkit/polite'
require 'set'
require 'gem_hadar/version'
require_maybe 'simplecov'
require_maybe 'rubygems/package_task'
require_maybe 'rcov/rcovtask'
require_maybe 'rspec/core/rake_task'

def GemHadar(&block)
  GemHadar.new(&block).create_all_tasks
end

class GemHadar
  if defined?(::RbConfig)
    include ::RbConfig
  else
    include ::Config
  end
  include Rake::DSL
  extend DSLKit::DSLAccessor
  include Spruz::SecureWrite

  def initialize(&block)
    @dependencies = []
    @development_dependencies = []
    block and instance_eval(&block)
  end

  def has_to_be_set(name)
    fail "#{self.class}: #{name} has to be set for gem"
  end

  dsl_accessor :name do
    has_to_be_set :name
  end

  dsl_accessor :name_version do
    [ name, version ] * '-'
  end

  dsl_accessor :module_type, :module

  dsl_accessor :author do
    has_to_be_set :author
  end

  dsl_accessor :email do
    has_to_be_set :email
  end

  dsl_accessor :homepage do
    has_to_be_set :homepage
  end

  dsl_accessor :summary do
    has_to_be_set :summary
  end

  dsl_accessor :description do
    has_to_be_set :description
  end

  dsl_accessor :require_paths do Set['lib'] end

  def require_path(path = nil)
    if path
      self.require_paths = Set[path]
    else
      require_paths.first
    end
  end

  dsl_accessor :readme

  dsl_accessor :title

  dsl_accessor :ignore_files do Set[] end

  dsl_accessor :test_dir

  dsl_accessor :bindir

  dsl_accessor :executables do Set[] end

  dsl_accessor :licenses do Set[] end

  dsl_accessor :test_files do
    if test_dir
      FileList[File.join(test_dir, '**/*.rb')]
    else
      FileList.new
    end
  end

  dsl_accessor :spec_dir

  dsl_accessor :spec_pattern do
    if spec_dir
      "#{spec_dir}{,/*/**}/*_spec.rb"
    else
      'spec{,/*/**}/*_spec.rb'
    end
  end

  dsl_accessor :doc_files do
    FileList[File.join('lib/**/*.rb')] + FileList[File.join('ext/**/*.c')]
  end

  dsl_accessor :extensions do FileList['ext/**/extconf.rb'] end

  dsl_accessor :make do
    ENV['MAKE'] || %w[gmake make].find { |c| system(c, '-v') }
  end

  dsl_accessor :files do
    `git ls-files`.split("\n")
  end

  dsl_accessor :path_name do name end

  dsl_accessor :path_module do path_name.camelize end

  dsl_accessor :version do
    begin
      File.read('VERSION').chomp
    rescue Errno::ENOENT
      has_to_be_set :version
    end
  end

  dsl_accessor :version_epilogue

  dsl_accessor :post_install_message

  class RvmConfig
    extend DSLKit::DSLAccessor
    include DSLKit::BlockSelf

    def initialize(&block)
      @outer_scope = block_self(&block)
      instance_eval(&block)
    end

    dsl_accessor :use do `rvm tools strings`.split(/\n/).full?(:last) || 'ruby' end

    dsl_accessor :gemset do @outer_scope.name end
  end

  def rvm(&block)
    if block
      @rvm = RvmConfig.new(&block)
    elsif !@rvm
      @rvm = RvmConfig.new { }
    end
    @rvm
  end

  dsl_accessor :default_task_dependencies, [ :gemspec, :test ]

  def default_task
    desc 'Default task'
    task :default => default_task_dependencies
  end

  dsl_accessor :build_task_dependencies, [ :clobber, :gemspec, :package, :'version:tag' ]

  def build_task
    desc 'Build task (builds all packages for a release)'
    task :build => build_task_dependencies
  end

  def install_library(&block)
    @install_library_block = lambda do
      desc 'Install executable/library into site_ruby directories'
      task :install => :prepare_install, &block
    end
  end

  def clean(*args)
    if args.empty?
      CLEAN
    else
      CLEAN.include(*args)
    end
  end

  def clobber(*args)
    if args.empty?
      CLOBBER
    else
      CLOBBER.include(*args)
    end
  end

  def ignore(*args)
    if args.empty?
      ignore_files
    else
      args.each { |a| ignore_files << a }
    end
  end

  def dependency(*args)
    @dependencies << args
  end

  def development_dependency(*args)
    @development_dependencies << args
  end

  def gems_install_task(&block)
    block ||= proc {  sh 'bundle install' }
    desc 'Install all gems from the Gemfile'
    namespace :gems do
      task :install => :gemspec , &block
    end
  end

  def gemspec
    Gem::Specification.new do |s|
      s.name        = name
      s.version     = ::Gem::Version.new(version)
      s.author      = author
      s.email       = email
      s.homepage    = homepage
      s.summary     = summary
      s.description = description
      files.full? { |f| s.files = Array(f) }
      test_files.full? { |t| s.test_files = Array(t) }
      extensions.full? { |e| s.extensions = Array(e) }
      bindir.full? { |b| s.bindir = b }
      executables.full? { |e| s.executables = Array(e) }
      licenses.full? { |l| s.licenses = Array(licenses) }
      post_install_message.full? { |m| s.post_install_message = m }

      s.add_development_dependency('gem_hadar', "~>#{VERSION}")
      for d in @development_dependencies
        s.add_development_dependency(*d)
      end
      for d in @dependencies
        s.add_dependency(*d)
      end

      require_paths.full? { |r| s.require_paths = Array(r) }

      if title
        s.rdoc_options << '--title' << title
      else
        s.rdoc_options << '--title' << "#{name.camelize} - #{summary}"
      end
      if readme
        s.rdoc_options << '--main' << readme
        s.extra_rdoc_files << readme
      end
      doc_files.full? { |df| s.extra_rdoc_files.concat Array(df) }
    end
  end

  def version_task
    desc m = "Writing version information for #{name}-#{version}"
    task :version do
      puts m
      mkdir_p dir = File.join('lib', path_name)
      secure_write(File.join(dir, 'version.rb')) do |v|
        v.puts <<EOT
#{module_type} #{path_module}
  # #{path_module} version
  VERSION         = '#{version}'
  VERSION_ARRAY   = VERSION.split('.').map(&:to_i) # :nodoc:
  VERSION_MAJOR   = VERSION_ARRAY[0] # :nodoc:
  VERSION_MINOR   = VERSION_ARRAY[1] # :nodoc:
  VERSION_BUILD   = VERSION_ARRAY[2] # :nodoc:
end
EOT
        version_epilogue.full? { |ve| v.puts ve }
      end
    end
  end

  def gemspec_task
    desc 'Create a gemspec file'
    task :gemspec => :version do
      filename = "#{name}.gemspec"
      warn "Writing to #{filename.inspect} for #{version}"
      secure_write(filename, gemspec.to_ruby)
    end
  end

  def package_task
    Gem::PackageTask.new(gemspec) do |pkg|
      pkg.need_tar      = true
      pkg.package_files += files
    end
  end

  def install_library_task
    @install_library_block.full?(:call)
  end

  def doc_task
    clean 'doc'
    desc "Creating documentation"
    task :doc do
      cmd = 'sdoc'
      if readme
        cmd << " --main '#{readme}'"
      end
      if title
        cmd << " --title '#{title}'"
      else
        cmd << " --title '#{name.camelize} - #{summary}'"
      end
      cmd << ' ' << doc_files * ' '
      if readme
        cmd << " #{readme}"
      end
      sh cmd
    end
  end

  def test_task
    tt =  Rake::TestTask.new(:run_tests) do |t|
      t.libs << test_dir
      t.libs.concat require_paths.to_a
      t.test_files = test_files
      t.verbose    = true
    end
    desc 'Run the tests'
    task :test => [ (:compile if extensions.full?), tt.name ].compact
  end

  def spec_task
    if defined?(::RSpec::Core::RakeTask)
      st =  RSpec::Core::RakeTask.new(:run_specs) do |t|
        t.ruby_opts ||= ''
        t.ruby_opts << ' -I' << ([ spec_dir ] + require_paths.to_a).uniq * ':'
        t.pattern = spec_pattern
        t.verbose = true
      end
      task :spec => [ (:compile if extensions.full?), st.name ].compact
    end
  end

  def rcov_task
    if defined?(::Rcov)
      rt = ::Rcov::RcovTask.new(:run_rcov) do |t|
        t.libs << test_dir
        t.libs.concat require_paths.to_a
        t.libs.uniq!
        t.test_files = test_files
        t.verbose    = true
        t.rcov_opts  = %W[-x '\\b#{test_dir}\/' -x '\\bgems\/']
      end
      desc 'Run the rcov code coverage tests'
      task :rcov => [ (:compile if extensions.full?), rt.name ].compact
      clobber 'coverage'
    else
      desc 'Run the rcov code coverage tests'
      task :rcov do
        warn "rcov doesn't work for some reason, have you tried 'gem install rcov'?"
      end
    end
  end

  def self.start_simplecov
    filter = "#{File.basename(File.dirname(caller.first))}/"
    require_maybe 'simplecov'
    defined?(SimpleCov) and
      SimpleCov.start do
        add_filter filter
      end
  end

  def write_ignore_file 
    secure_write('.gitignore') do |output|
      output.puts(ignore.sort)
    end
  end

  def write_gemfile
     default_gemfile =<<EOT
# vim: set filetype=ruby et sw=2 ts=2:

source 'https://rubygems.org'

gemspec
EOT
    current_gemfile = File.exist?('Gemfile') && File.read('Gemfile')
    case current_gemfile
    when false
      secure_write('Gemfile') do |output|
        output.write default_gemfile
      end
    when default_gemfile
      ;;
    else
      warn "INFO: Current Gemfile differs from default Gemfile."
    end
  end

  def version_tag_task
    namespace :version do
      desc "Tag this commit as version #{version}"
      task :tag do
        begin
          sh "git tag -a -m 'Version #{version}' #{'-f' if ENV['FORCE']} v#{version}"
        rescue RuntimeError
          warn "Call rake with FORCE=1 to overwrite version tag #{version}"
          exit 1
        end
      end
    end
  end

  def git_remote
    ENV['GIT_REMOTE'] || 'origin'
  end

  def version_push_task
    namespace :version do
      desc "Push all versions to GIT_REMOTE=#{git_remote}"
      task :push do
        sh "git push #{git_remote} --tags"
      end
    end
  end

  def master_push_task
    namespace :master do
      desc "Push master to git remote"
      task :push do
        sh "git push #{git_remote} master"
      end
    end
  end

  def gem_push_task
    namespace :gem do
      path = "pkg/#{name_version}.gem"
      desc "Push gem file #{File.basename(path)} to rubygems"
      task :push do
        if File.exist?(path)
          if ask?("Do you really want to push #{path.inspect} to rubygems? "\
            "(yes/NO) ", /\Ayes\z/i)
          then
            sh "gem push #{path}"
          else
            exit 1
          end
        else
          warn "Cannot push gem to rubygems: #{path.inspect} doesn't exist."
          exit 1
        end
      end
    end
  end

  def compile_task
    for file in extensions
      dir = File.dirname(file)
      clean File.join(dir, 'Makefile'), File.join(dir, '*.{bundle,o,so}')
    end
    desc "Compile extensions: #{extensions * ', '}"
    task :compile do
      for file in extensions
        dir, file = File.split(file)
        cd dir do
          ruby file
          sh make
        end
      end
    end
  end

  def rvm_task
    desc 'Create .rvmrc file'
    task :rvm do
      secure_write('.rvmrc') do |output|
        output.write <<EOT
rvm use #{rvm.use}
rvm gemset create #{rvm.gemset}
rvm gemset use #{rvm.gemset}
EOT
      end
    end
  end

  def ask?(prompt, pattern)
    STDOUT.print prompt
    answer = STDIN.gets.chomp
    if answer =~ pattern
      $~
    end
  end

  def create_all_tasks
    default_task
    build_task
    rvm_task
    version_task
    gemspec_task
    gems_install_task
    doc_task
    if test_dir
      test_task
      rcov_task
    end
    spec_task
    package_task
    install_library_task
    version_tag_task
    version_push_task
    master_push_task
    write_ignore_file
    write_gemfile
    gem_push_task
    if extensions.full?
      compile_task
      task :prepare_install => :compile
    else
      task :prepare_install
    end
    self
  end
end
