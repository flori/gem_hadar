require 'rubygems'
require 'rbconfig'
if defined?(::RbConfig)
  include ::RbConfig
else
  include ::Config
end
require 'rake'
require 'net/http'
require 'uri'
require 'tins/xt'
require 'tins/secure_write'
require 'rake/clean'
require 'rake/testtask'
require 'dslkit/polite'
require 'set'
require 'pathname'
require 'erb'
require 'gem_hadar/version'
require_maybe 'yard'
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
  include Tins::SecureWrite

  def initialize(&block)
    @dependencies = []
    @development_dependencies = []
    block and instance_eval(&block)
  end

  def has_to_be_set(name)
    fail "#{self.class}: #{name} has to be set for gem"
  end

  def assert_valid_link(name, orig_url)
    developing and return orig_url
    url = orig_url
    begin
      response = Net::HTTP.get_response(URI.parse(url))
      url = response['location']
    end while response.is_a?(Net::HTTPRedirection)
    response.is_a?(Net::HTTPOK) or
      fail "#{orig_url.inspect} for #{name} has to be a valid link"
    orig_url
  end

  dsl_accessor :developing, false

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

  dsl_accessor :yard_dir do
    'yard'
  end

  dsl_accessor :extensions do FileList['ext/**/extconf.rb'] end

  dsl_accessor :make do
    ENV['MAKE'] || %w[gmake make].find { |c| system(c, '-v') }
  end

  dsl_accessor :files do
    `git ls-files`.split("\n")
  end

  dsl_accessor :package_ignore_files do
    Set[]
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

  dsl_accessor :required_ruby_version

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

  def package_ignore(*args)
    if args.empty?
      package_ignore_files
    else
      args.each { |a| package_ignore_files << a }
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

  def gem_files
    (files.to_a - package_ignore_files.to_a)
  end

  def gemspec
    Gem::Specification.new do |s|
      s.name        = name
      s.version     = ::Gem::Version.new(version)
      s.author      = author
      s.email       = email
      s.homepage    = assert_valid_link(:homepage, homepage)
      s.summary     = summary
      s.description = description

      gem_files.full? { |f| s.files = Array(f) }
      test_files.full? { |t| s.test_files = Array(t) }
      extensions.full? { |e| s.extensions = Array(e) }
      bindir.full? { |b| s.bindir = b }
      executables.full? { |e| s.executables = Array(e) }
      licenses.full? { |l| s.licenses = Array(licenses) }
      post_install_message.full? { |m| s.post_install_message = m }

      required_ruby_version.full? { |v| s.required_ruby_version = v }
      s.add_development_dependency('gem_hadar', "~>#{VERSION}")
      for d in @development_dependencies
        s.add_development_dependency(*d)
      end
      for d in @dependencies
        if s.respond_to?(:add_runtime_dependency)
          s.add_runtime_dependency(*d)
        else
          s.add_dependency(*d)
        end
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

  def version_show_task
    namespace :version do
      desc m = "Displaying the current version"
      task :show do
        require path_name
        dir = File.join('lib', path_name)
        version_file = File.join(dir, 'version.rb')
        m = Module.new
        m.instance_eval File.read(version_file)
        version_rb   = m.const_get(
          [ path_module, 'VERSION' ] * '::'
        )
        equal        = version == version_rb ? '==' : '!='
        puts "version.rb=#{version_rb} #{equal} VERSION=#{version}"
      end
    end
  end

  def version_diff_task
    namespace :version do
      desc m = "Displaying the diff from HEAD to the last version tag"
      task :diff do
        puts `git diff --color=always v#{version}..HEAD`
      end
    end
  end

  def gem_hadar_update_task
    namespace :gem_hadar do
      desc 'Update gem_hadar a different version'
      task :update do
        answer = ask?("Which gem_hadar version? ", /^((?:\d+.){2}(?:\d+))$/)
        unless answer
          warn "Invalid version specification!"
          exit 1
        end
        gem_hadar_version = answer[0]
        filename = "#{name}.gemspec"
        old_data = File.read(filename)
        new_data = old_data.gsub(
          /(add_(?:development_)?dependency\(%q<gem_hadar>, \["~> )([\d.]+)("\])/
        ) { "#$1#{gem_hadar_version}#$3" }
        if old_data == new_data
          warn "#{filename.inspect} already depends on gem_hadar "\
            "#{gem_hadar_version} => Do nothing."
        else
          warn "Upgrading #{filename.inspect} to #{gem_hadar_version}."
          secure_write(filename) do |spec|
            spec.write new_data
          end
        end
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
      pkg.package_files += gem_files
    end
  end

  def install_library_task
    @install_library_block.full?(:call)
  end

  def doc_task
    clean 'doc'
    desc "Creating documentation"
    task :doc do
      sh 'yard doc'
      cmd = 'yardoc'
      if readme
        cmd << " --readme '#{readme}'"
      end
      cmd << ' - ' << doc_files * ' '
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
    defined? ::RSpec::Core::RakeTask or return
    st =  RSpec::Core::RakeTask.new(:run_specs) do |t|
      t.ruby_opts ||= ''
      t.ruby_opts << ' -I' << ([ spec_dir ] + require_paths.to_a).uniq * ':'
      t.pattern = spec_pattern
      t.verbose = true
    end
    task :spec => [ (:compile if extensions.full?), st.name ].compact
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
    defined? SimpleCov or return
    filter = "#{File.basename(File.dirname(caller.first))}/"
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

  def version_bump_task
    namespace :version do
      namespace :bump do
        desc 'Bump major version'
        task :major do
          version = File.read('VERSION').chomp.version
          version.bump(:major)
          secure_write('VERSION') { |v| v.puts version }
        end

        desc 'Bump minor version'
        task :minor do
          version = File.read('VERSION').chomp.version
          version.bump(:minor)
          secure_write('VERSION') { |v| v.puts version }
        end

        desc 'Bump build version'
        task :build do
          version = File.read('VERSION').chomp.version
          version.bump(:build)
          secure_write('VERSION') { |v| v.puts version }
        end
      end
    end
  end

  def version_tag_task
    namespace :version do
      desc "Tag this commit as version #{version}"
      task :tag do
        force = ENV['FORCE'].to_i == 1
        begin
          sh "git tag -a -m 'Version #{version}' #{'-f' if force} v#{version}"
        rescue RuntimeError
          if `git diff v#{version}..HEAD`.empty?
            puts "Version #{version} is already tagged, but it's no different"
          else
            if ask?("Different version tag #{version} already exists. Overwrite with "\
                "force? (yes/NO) ", /\Ayes\z/i)
              force = true
              retry
            else
              exit 1
            end
          end
        end
      end
    end
  end

  def git_remote
    ENV.fetch('GIT_REMOTE', 'origin').split(/\s+/).first
  end

  def git_remotes
    remotes = ENV['GIT_REMOTE'].full?(:split, /\s+/)
    remotes or remotes = `git remote`.lines.map(&:chomp)
    remotes
  end

  def master_prepare_task
    namespace :master do
      desc "Prepare a remote git repository for this project"
      task :prepare do
        puts "Create a new remote git repository for #{name.inspect}"
        remote_name = ask?('Name (default: origin) ? ', /^.+$/).
          full?(:[], 0) || 'origin'
        dir         = ask?("Directory (default: /git/#{name}.git)? ", /^.+$/).
          full?(:[], 0) || "/git/#{name}.git"
        ssh_account = ask?('SSH account (format: login@host)? ', /^[^@]+@[^@]+/).
          full?(:[], 0) || exit(1)
        sh "ssh #{ssh_account} 'git init --bare #{dir}'"
        sh "git remote add -m master #{remote_name} #{ssh_account}:#{dir}"
      end
    end
  end

  def version_push_task
    namespace :version do
      git_remotes.each do |gr|
        namespace gr.to_sym do
          desc "Push version #{version} to git remote #{gr}"
          task :push do
            sh "git push #{gr} v#{version}"
          end
        end
      end

      desc "Push version #{version} to all git remotes: #{git_remotes * ' '}"
      task :push => git_remotes.map { |gr| :"version:#{gr}:push" }
    end
  end

  def master_push_task
    namespace :master do
      git_remotes.each do |gr|
        namespace gr.to_sym do
          desc "Push master to git remote #{gr}"
          task :push do
            sh "git push #{gr} master"
          end
        end
      end

      desc "Push master #{version} to all git remotes: #{git_remotes * ' '}"
      task :push => git_remotes.map { |gr| :"master:#{gr}:push" }
    end
  end

  def gem_push_task
    namespace :gem do
      path = "pkg/#{name_version}.gem"
      desc "Push gem file #{File.basename(path)} to rubygems"
      if developing
        task :push => :build do
          puts "Skipping push to rubygems while developing mode is enabled."
        end
      else
        task :push => :build do
          if File.exist?(path)
            if ask?("Do you really want to push #{path.inspect} to rubygems? "\
                "(yes/NO) ", /\Ayes\z/i)
              then
              key = ENV['GEM_API_KEY'].full? { |k| "--key #{k} " }
              sh "gem push #{key}#{path}"
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
  end

  def git_remotes_task
    task :git_remotes do
      puts git_remotes.map { |r|
        url = `git remote get-url #{r.inspect}`.chomp
        "#{r} #{url}"
      }
    end
  end

  def push_task
    master_prepare_task
    version_push_task
    master_push_task
    gem_push_task
    git_remotes_task
    task :modified do
      changed_files = `git status --porcelain`.gsub(/^\s*\S\s+/, '').lines
      unless changed_files.empty?
        warn "There are still modified files:\n#{changed_files * ''}"
        exit 1
      end
    end
    desc "Push master and version #{version} all git remotes: #{git_remotes * ' '}"
    task :push => %i[ modified build master:push version:push gem:push ]
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

  def yard_task
    defined? YARD or return
    namespace :yard do
      my_yard_dir = Pathname.new(yard_dir)

      desc 'Create yard documentation (including private)'
      task :private do
        sh "yardoc -o #{my_yard_dir}"
      end

      desc 'View the yard documentation'
      task :view do
        index_file = my_yard_dir + 'index.html'
        File.exist?(index_file)
        sh "open #{index_file}"
      end

      desc 'Clean the yard documentation'
      task :clean do
        rm_rf my_yard_dir
      end

      desc 'List all undocumented classes/modules/methods'
      task :'list-undoc' do
        sh "yard stats --list-undoc"
      end
    end

    desc 'Create the yard documentation and view it'
    task :yard => %i[ yard:private yard:view ]
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
    version_show_task
    version_diff_task
    gem_hadar_update_task
    gemspec_task
    gems_install_task
    doc_task
    if test_dir
      test_task
      rcov_task
    end
    spec_task
    package_task
    yard_task
    install_library_task
    version_bump_task
    version_tag_task
    push_task
    write_ignore_file
    write_gemfile
    if extensions.full?
      compile_task
      task :prepare_install => :compile
    else
      task :prepare_install
    end
    self
  end

  class TemplateCompiler
    include Tins::BlockSelf
    include Tins::MethodMissingDelegator::DelegatorModule

    def initialize(&block)
      super block_self(&block)
      @values = {}
      instance_eval(&block)
    end

    def compile(src, dst)
      template = File.read(src)
      File.open(dst, 'w') do |output|
        erb = ERB.new(template, nil, '-')
        erb.filename = src.to_s
        output.write erb.result binding
      end
    end

    def method_missing(id, *a, &b)
      if a.empty? && id && @values.key?(id)
        @values[id]
      elsif a.size == 1
        @values[id] = a.first
      else
        super
      end
    end
  end

  class Setup
    include FileUtils

    def perform
      mkdir_p 'lib'
      unless File.exist?('VERSION')
        File.open('VERSION', 'w') do |output|
          output.puts '0.0.0'
        end
      end
      unless File.exist?('Rakefile')
        File.open('Rakefile', 'w') do |output|
          output.puts <<~EOT
            # vim: set filetype=ruby et sw=2 ts=2:

            require 'gem_hadar'

            GemHadar do
              #developing true
              #name       'TODO'
              module_type :class
              #author     'TODO'
              #email      'todo@example.com'
              #homepage   "https://github.com/TODO/NAME"
              #summary    'TODO'
              description 'TODO'
              test_dir    'spec'
              ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.AppleDouble', '.bundle', '.yardoc', 'tags'
              readme      'README.md'

              #executables << 'bin/TODO'

              #dependency  'TODO', '~>1.2.3'

              #licenses << 'TODO
            end
          EOT
        end
      end
    end
  end
end

def template(pathname, &block)
  template_src = Pathname.new(pathname)
  template_dst = template_src.sub_ext('') # ignore ext, we just support erb anyway
  template_src == template_dst and raise ArgumentError,
    "pathname #{pathname.inspect} needs to have a file extension"
  file template_dst.to_s => template_src.to_s do
    GemHadar::TemplateCompiler.new(&block).compile(template_src, template_dst)
  end
  template_dst
end
