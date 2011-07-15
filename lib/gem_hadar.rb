
require 'rubygems'
require 'spruz/xt'
require 'rbconfig'
include Config
require 'rake'
begin
  require 'rubygems/package_task'
rescue LoadError
end
require 'rake/clean'
require 'rake/testtask'
require 'rcov/rcovtask'
require 'dslkit/polite'
require 'gem_hadar/version'

def GemHadar(&block)
  GemHadar.new(&block).create_all_tasks
end

class GemHadar
  include Config
  include Rake::DSL
  extend DSLKit::DSLAccessor

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

  dsl_accessor :require_path, 'lib'

  dsl_accessor :readme

  dsl_accessor :title

  dsl_accessor :ignore_files do @ignore_files = [] end

  dsl_accessor :test_dir

  dsl_accessor :test_files do
    if test_dir
      FileList[File.join(test_dir, '**/*.rb')]
    else
      FileList.new
    end
  end

  dsl_accessor :files do
    `git ls-files`.split("\n")
  end

  dsl_accessor :path_name do name end

  dsl_accessor :version do
    begin
      File.read('VERSION').chomp
    rescue Errno::ENOENT
      has_to_be_set :version
    end
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
      task :install, &block
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
      ignore_files.push(*args)
    end
  end

  def dependency(*args)
    @dependencies << args
  end

  def development_dependency(*args)
    @development_dependencies << args
  end

  def gems_install_task(&block)
    block ||= lambda {  sh 'bundle install' }
    desc 'Install all gems from the Gemfile'
    task :'gems:install', &block
  end

  def gemspec
    Gem::Specification.new do |s|
      s.name        = name
      s.version     = version
      s.author      = author
      s.email       = email
      s.homepage    = homepage
      s.summary     = summary
      s.description = description
      s.files       = files
      s.test_files  = test_files

      s.add_development_dependency('gem_hadar', "~>#{VERSION}")
      for d in @development_dependencies
        s.add_development_dependency(*d)
      end
      for d in @dependencies
        s.add_dependency(*d)
      end

      s.require_path = require_path

      if title
        s.rdoc_options << '--title' << title
      else
        s.rdoc_options << '--title' << "#{name.camelize} - #{summary}"
      end
      if readme
        s.rdoc_options << '--main' << readme
        s.extra_rdoc_files << readme
      end

    end
  end

  def version_task
    desc m = "Writing version information for #{name}-#{version}"
    task :version do
      puts m
      mkdir_p dir = File.join('lib', path_name)
      File.write(File.join(dir, 'version.rb')) do |v|
        v.puts <<EOT
#{module_type} #{path_name.camelize}
  # #{path_name.camelize} version
  VERSION         = '#{version}'
  VERSION_ARRAY   = VERSION.split(/\\./).map { |x| x.to_i } # :nodoc:
  VERSION_MAJOR   = VERSION_ARRAY[0] # :nodoc:
  VERSION_MINOR   = VERSION_ARRAY[1] # :nodoc:
  VERSION_BUILD   = VERSION_ARRAY[2] # :nodoc:
end
EOT
      end
    end
  end

  def gemspec_task
    desc 'Create a gemspec file'
    task :gemspec => :version do
      filename = "#{name}.gemspec"
      warn "Writing to #{filename.inspect} for #{version}"
      File.open(filename, 'w') do |output|
        output.write gemspec.to_ruby
      end
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
      cmd << ' ' << Dir['lib/**/*.rb'] * ' '
      if readme
        cmd << " #{readme}"
      end
      sh cmd
    end
  end

  def test_task
    Rake::TestTask.new do |t|
      t.libs << test_dir
      t.test_files = test_files
      t.verbose    = true
    end
  end

  def rcov_task
    Rcov::RcovTask.new do |t|
      t.libs << test_dir
      t.test_files = test_files
      t.verbose    = true
      t.rcov_opts  = %W[-x '\\b#{test_dir}\/' -x '\\bgems\/']
    end
  end

  def write_ignore_file 
    File.write('.gitignore') do |output|
      output.puts ignore
    end
  end

  def write_gemfile
    File.write('Gemfile') do |output|
      output.puts <<EOT
# vim: set filetype=ruby et sw=2 ts=2:

source :rubygems

gemspec
EOT
    end
  end

  def version_tag_task
    namespace :version do
      desc "Tag this commit as version #{version}"
      task :tag do
        begin
          sh "git tag -a -m 'Version #{version}' #{'-f' if ENV['FORCE']} v#{version}"
        rescue RuntimeError => e
          warn "Call rake with FORCE=1 to overwrite version tag #{version}"
          exit 1
        end
      end
    end
  end

  def create_all_tasks
    default_task
    build_task
    version_task
    gemspec_task
    gems_install_task
    doc_task
    if test_dir
      test_task
      rcov_task
    end
    package_task
    install_library_task
    version_tag_task
    write_ignore_file
    write_gemfile
    self
  end
end
