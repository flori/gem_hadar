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
require 'ollama'
require 'term/ansicolor'
require_maybe 'yard'
require_maybe 'simplecov'
require_maybe 'rubygems/package_task'
require_maybe 'rcov/rcovtask'
require_maybe 'rspec/core/rake_task'

# A brief description of the GemHadar class.
#
# The GemHadar class serves as the primary configuration and task management
# framework for Ruby gem projects. It provides a DSL for defining gem metadata,
# dependencies, and Rake tasks, while also offering integration with various
# tools such as GitHub, SimpleCov, YARD, and Ollama for automating common
# development workflows.
#
# @example Configuring a gem using the GemHadar DSL
#   GemHadar do
#     name        'my_gem'
#     version     '1.0.0'
#     author      'John Doe'
#     email       'john@example.com'
#     homepage    'https://github.com/example/my_gem'
#     summary     'A brief description'
#     description 'A longer description of the gem'
#     test_dir    'spec'
#   end
#
# @example Creating a Rake task for building and packaging the gem
#   GemHadar do
#     name 'my_gem'
#     # ... other configuration ...
#     build_task
#   end
#
# @example Setting up version bumping with AI assistance
#   GemHadar do
#     name 'my_gem'
#     # ... other configuration ...
#     version_bump_task
#   end
class GemHadar
end
require 'gem_hadar/version'
require 'gem_hadar/utils'
require 'gem_hadar/warn'
require 'gem_hadar/setup'
require 'gem_hadar/template_compiler'
require 'gem_hadar/github'
require 'gem_hadar/prompt_template'

class GemHadar
  include Term::ANSIColor
  include GemHadar::Utils
  include GemHadar::PromptTemplate
  include GemHadar::Warn

  if defined?(::RbConfig)
    include ::RbConfig
  else
    include ::Config
  end
  include Rake::DSL
  extend DSLKit::DSLAccessor
  include Tins::SecureWrite

  # The initialize method sets up the GemHadar instance by initializing
  # dependency arrays and evaluating a configuration block.
  #
  # @param block [Proc] optional configuration block to set gem properties and settings
  #
  # @return [GemHadar] the initialized GemHadar instance
  def initialize(&block)
    @dependencies = []
    @development_dependencies = []
    block and instance_eval(&block)
  end

  # The has_to_be_set method raises an error if a required gem configuration
  # attribute is not set.
  #
  # @param name [ String ] the name of the required attribute
  #
  # @raise [ ArgumentError ] if the specified attribute has not been set
  def has_to_be_set(name)
    fail "#{self.class}: #{name} has to be set for gem"
  end

  # The developing attribute accessor for configuring development mode.
  #
  # This method sets up a DSL accessor for the developing attribute, which
  # controls whether the gem is in development mode. When set to true, certain
  # behaviors such as skipping gem pushes are enabled as well as asserting the
  # validity of the homepage link.
  #
  # @return [ Boolean ] the current value of the developing flag
  dsl_accessor :developing, false

  # The name attribute accessor for configuring the gem's name.
  #
  # This method sets up a DSL accessor for the name attribute, which specifies
  # the identifier for the gem. It includes a validation step that raises an
  # ArgumentError if the name has not been set, ensuring that the gem
  # configuration contains a required name value.
  #
  # @return [ String ] the name of the gem
  #
  # @raise [ ArgumentError ] if the name attribute has not been set
  dsl_accessor :name do
    has_to_be_set :name
  end

  # The name_version method computes and returns the combined gem name and
  # version string.
  #
  # This method constructs a version identifier by joining the gem's name and
  # current version with a hyphen separator. It is typically used to generate
  # filenames or identifiers that incorporate both the gem name and its version
  # number for packaging, tagging, or display purposes.
  #
  # @return [ String ] the combined gem name and version in the format "name-version"
  dsl_accessor :name_version do
    [ name, version ] * '-'
  end

  # The module_type attribute accessor for configuring the type of Ruby construct to generate for version code.
  #
  # This method sets up a DSL accessor for the module_type attribute, which determines whether the generated code
  # structure for the version module should be a :module or :class. This controls the type of Ruby construct
  # created when generating code skeletons and version files. The value can be set to either:
  #
  # - :module (default) - Generates module-based structure
  # - :class - Generates class-based structure
  #
  # This is used in the generated version.rb file to create either:
  #
  #   module MyGem
  #     # ... version constants
  #   end
  #
  # or
  #
  #   class MyGem
  #     # ... version constants
  #   end
  #
  # @return [ Symbol ] the type of Ruby construct to generate (:module or :class)
  dsl_accessor :module_type, :module

  # The has_to_be_set method raises an error if a required gem configuration
  # attribute is not set.
  #
  # This method is used to validate that essential gem configuration attributes
  # have been provided. When called, it will raise an ArgumentError with a
  # descriptive message indicating which attribute is missing and needs to be
  # configured.
  #
  # @param name [ String ] the name of the required attribute
  #
  # @raise [ ArgumentError ] if the specified attribute has not been set
  dsl_accessor :author do
    has_to_be_set :author
  end

  # The email attribute accessor for configuring the gem's author email.
  #
  # This method sets up a DSL accessor for the email attribute, which specifies
  # the contact email address for the gem's author. It includes a
  # validation step that raises an ArgumentError if the email has not been
  # set, ensuring that the gem configuration contains this required
  # information.
  #
  # @return [ String ] the author's email address
  #
  # @raise [ ArgumentError ] if the email attribute has not been set
  dsl_accessor :email do
    has_to_be_set :email
  end

  # The homepage attribute accessor for configuring the gem's homepage URL.
  #
  # This method sets up a DSL accessor for the homepage attribute, which
  # specifies the URL of the gem's official repository or project page. It
  # includes a validation step that raises an ArgumentError if the homepage has
  # not been set, ensuring that the gem configuration contains this required
  # information. When the developing flag is false, it also validates that the
  # provided URL returns an HTTP OK status after following redirects.
  #
  # @return [ String ] the homepage URL of the gem
  #
  # @raise [ ArgumentError ] if the homepage attribute has not been set
  # @raise [ ArgumentError ] if the homepage URL is invalid and developing mode is disabled
  dsl_accessor :homepage do
    has_to_be_set :homepage
  end

  # The summary attribute accessor for configuring the gem's summary.
  #
  # This method sets up a DSL accessor for the summary attribute, which
  # specifies a brief description of what the gem does. It includes a
  # validation step that raises an ArgumentError if the summary has not been
  # set, ensuring that the gem configuration contains this required
  # information.
  #
  # @return [ String ] the summary of the gem
  #
  # @raise [ ArgumentError ] if the summary attribute has not been set
  dsl_accessor :summary do
    has_to_be_set :summary
  end

  # The description attribute accessor for configuring the gem's description.
  #
  # This method sets up a DSL accessor for the description attribute, which
  # specifies the detailed explanation of what the gem does. It includes a
  # validation step that raises an ArgumentError if the description has not
  # been set, ensuring that the gem configuration contains this required
  # information.
  #
  # @return [ String ] the description of the gem
  #
  # @raise [ ArgumentError ] if the description attribute has not been set
  dsl_accessor :description do has_to_be_set :description end

  # The require_paths attribute accessor for configuring the gem's require
  # paths.
  #
  # This method sets up a DSL accessor for the require_paths attribute, which
  # specifies the directories from which the gem's code can be loaded. It
  # provides a way to define the locations of the library files that will be
  # made available to users of the gem when it is required in Ruby programs.
  #
  # @return [ Set<String> ] a set of directory paths to be included in the load
  # path
  dsl_accessor :require_paths do Set['lib'] end

  # The require_path method manages the gem's require path configuration.
  #
  # This method provides functionality to set or retrieve the directory paths
  # from which the gem's code can be loaded. When called with a path argument,
  # it updates the require_paths attribute with that path and returns it.
  # When called without arguments, it returns the first path from the current
  # require_paths set.
  #
  # @param path [ String, nil ] the directory path to set as the require path;
  #                           if nil, returns the current first require path
  #
  # @return [ String ] the specified path when setting, or the first require
  # path when retrieving
  def require_path(path = nil)
    if path
      self.require_paths = Set[path]
      path
    else
      require_paths.first
    end
  end

  # The readme attribute accessor for configuring the gem's README file.
  #
  # This method sets up a DSL accessor for the readme attribute, which specifies
  # the path to the README file for the gem. It provides a way to define the
  # location of the README file that will be used in documentation and packaging
  # processes.
  #
  # @return [ String, nil ] the path to the README file or nil if not set
  dsl_accessor :readme

  # The title attribute accessor for configuring the gem's documentation title.
  #
  # This method sets up a DSL accessor for the title attribute, which specifies
  # the title to be used in the generated YARD documentation. It provides a way
  # to define a custom title that will be included in the documentation output,
  # making it easier to identify and reference the gem's documentation.
  #
  # @return [ String, nil ] the documentation title or nil if not set
  dsl_accessor :title

  # The ignore_files attribute accessor for configuring files to be ignored by
  # the gem.
  #
  # This method sets up a DSL accessor for the ignore_files attribute, which
  # specifies a set of file patterns that should be excluded from various gem
  # operations and processing tasks. It provides a way to define ignore rules
  # that apply broadly across the gem's functionality, including but not
  # limited to build processes, documentation generation, and version control
  # integration.
  #
  # @return [ Set<String> ] a set of file patterns to be ignored by the gem's operations
  dsl_accessor :ignore_files do Set[] end

  # The bindir attribute accessor for configuring the gem's binary directory.
  #
  # This method sets up a DSL accessor for the bindir attribute, which specifies
  # the directory where executable scripts (binaries) are installed when the gem
  # is packaged and installed. It provides a way to define the location of the
  # bin directory that will contain the gem's executable files.
  #
  # @return [ String, nil ] the path to the binary directory or nil if not set
  dsl_accessor :bindir

  # The executables attribute accessor for configuring the gem's executable
  # files.
  #
  # This method sets up a DSL accessor for the executables attribute, which
  # specifies the list of executable scripts that should be installed as part
  # of the gem. It provides a way to define one or more executable file names
  # that will be made available in the gem's bin directory when the gem is
  # installed.
  #
  # @return [ Set<String> ] a set of executable file names to be included with
  # the gem
  dsl_accessor :executables do Set[] end

  # The licenses attribute accessor for configuring the gem's license
  # information.
  #
  # This method sets up a DSL accessor for the licenses attribute, which
  # specifies the license(s) under which the gem is distributed. It provides a
  # way to define one or more licenses that apply to the gem, defaulting to an
  # empty Set if none are explicitly configured.
  #
  # @return [ Set<String> ] a set of license identifiers applied to the gem
  dsl_accessor :licenses do Set[] end

  # The test_dir attribute accessor for configuring the test directory.
  #
  # This method sets up a DSL accessor for the test_dir attribute, which specifies
  # the directory where test files are located. It provides a way to define the
  # location of the test directory that will be used by various testing tasks and
  # configurations within the gem project.
  #
  # @return [ String, nil ] the path to the test directory or nil if not set
  dsl_accessor :test_dir

  # The test_files attribute accessor for configuring the list of test files to
  # be included in the gem package.
  #
  # This method sets up a DSL accessor for the test_files attribute, which
  # specifies the files that should be included when running tests for the gem.
  # It provides a way to customize the test file discovery process, defaulting
  # to finding all Ruby files ending in _spec.rb within the spec directory and
  # its subdirectories.
  #
  # @return [ FileList ] a list of file paths to be included in test execution
  dsl_accessor :test_files do
    if test_dir
      FileList[File.join(test_dir, '**/*.rb')]
    else
      FileList.new
    end
  end

  # The spec_dir attribute accessor for configuring the RSpec specification
  # directory.
  #
  # This method sets up a DSL accessor for the spec_dir attribute, which
  # specifies the directory where RSpec test files are located. It provides a
  # way to customize the location of test specifications separate from the
  # default 'spec' directory, allowing for more flexible project structures.
  #
  # @return [ String, nil ] the path to the RSpec specification directory or
  # nil if not set
  dsl_accessor :spec_dir

  # The spec_pattern method configures the pattern used to locate RSpec test
  # files.
  #
  # This method sets up a DSL accessor for the spec_pattern attribute, which
  # defines the file pattern used to discover RSpec test files in the project.
  # It defaults to a standard pattern that looks for files ending in _spec.rb
  # within the spec directory and its subdirectories, but can be customized
  # through the configuration block.
  #
  # @return [ String ] the file pattern used to locate RSpec test files
  dsl_accessor :spec_pattern do
    if spec_dir
      "#{spec_dir}{,/*/**}/*_spec.rb"
    else
      'spec{,/*/**}/*_spec.rb'
    end
  end

  # The doc_code_files method manages the list of code files to be included in
  # documentation generation.
  #
  # This method sets up a DSL accessor for the doc_code_files attribute, which
  # specifies the Ruby source files that should be processed when generating
  # YARD documentation. It defaults to using the files attribute and provides a
  # way to customize which code files are included in the documentation build
  # process.
  #
  # @return [ FileList ] a list of file paths to be included in YARD documentation generation
  # @see GemHadar#files
  dsl_accessor :doc_code_files do
    files
  end

  # The doc_files attribute accessor for configuring additional documentation
  # files.
  #
  # This method sets up a DSL accessor for the doc_files attribute, which
  # specifies additional files to be included in the YARD documentation
  # generation process. It defaults to an empty FileList and provides a way to
  # define extra documentation files that should be processed alongside the
  # standard library source files.
  #
  # @return [ FileList ] a list of file paths to be included in YARD
  # documentation
  dsl_accessor :doc_files do
    FileList[File.join('lib/**/*.rb')] + FileList[File.join('ext/**/*.c')]
  end

  # The yard_dir attribute accessor for configuring the output directory for
  # YARD documentation.
  #
  # This method sets up a DSL accessor for the yard_dir attribute, which
  # specifies the directory where YARD documentation will be generated. It
  # defaults to 'doc' and provides a way to customize the documentation output
  # location through the configuration block.
  #
  # @return [ String ] the path to the directory where YARD documentation will be stored
  dsl_accessor :yard_dir do
    'doc'
  end

  # The extensions attribute accessor for configuring project extensions.
  #
  # This method sets up a DSL accessor for the extensions attribute, which
  # specifies the list of extension configuration files (typically extconf.rb)
  # that should be compiled when building the gem. It defaults to finding all
  # extconf.rb files within the ext directory and its subdirectories, making it
  # easy to include native extensions in the gem package.
  #
  # @return [ FileList ] a list of file paths to extension configuration files
  #                      to be compiled during the build process
  dsl_accessor :extensions do FileList['ext/**/extconf.rb'] end

  # The make method retrieves the make command to be used for building
  # extensions.
  #
  # This method determines the appropriate make command to use when compiling
  # project extensions. It first checks for the MAKE environment variable and
  # returns its value if set. If the environment variable is not set, it
  # attempts to detect a suitable make command by testing for the existence of
  # 'gmake' and 'make' in the system PATH.
  #
  # @return [ String, nil ] the make command name or nil if none found
  dsl_accessor :make do
    ENV['MAKE'] || %w[gmake make].find { |c| system(c, '-v') }
  end

  # The files attribute accessor for configuring the list of files included in
  # the gem package.
  #
  # This method sets up a DSL accessor for the files attribute, which specifies
  # the complete set of files that should be included when building the gem
  # package. It defaults to retrieving the file list from Git using `git
  # ls-files` and provides a way to override this behavior through the
  # configuration block.
  #
  # @return [ Array<String> ] an array of file paths to be included in the gem package
  dsl_accessor :files do
    FileList[`git ls-files`.split("\n")]
  end

  # The package_ignore_files attribute accessor for configuring files to be
  # ignored during gem packaging.
  #
  # This method sets up a DSL accessor for the package_ignore_files attribute,
  # which specifies file patterns that should be excluded from the gem package
  # when it is built. It defaults to an empty set and provides a way to define
  # ignore rules specific to the packaging process, separate from general
  # project ignore rules.
  #
  # @return [ Set<String> ] a set of file patterns to be ignored during gem packaging
  dsl_accessor :package_ignore_files do
    Set[]
  end

  # The path_name attribute accessor for configuring the gem's path name.
  #
  # This method sets up a DSL accessor for the path_name attribute, which
  # determines the raw gem name value used for generating file paths and module
  # names. It defaults to the value of the name attribute and is particularly
  # useful for creating consistent directory structures and file naming
  # conventions. This value is used internally by GemHadar to create the root
  # directory for the gem and generate a version.rb file in that location.
  #
  # @return [ String ] the path name derived from the gem's name
  dsl_accessor :path_name do name end

  # The path_module attribute accessor for configuring the Ruby module name.
  #
  # This method sets up a DSL accessor for the path_module attribute, which
  # determines the camelized version of the gem's name to be used as the Ruby
  # module or class name. It automatically converts the value of path_name
  # into CamelCase format, ensuring consistency with Ruby naming conventions
  # for module and class declarations.
  #
  # @return [ String ] the camelized module name derived from path_name
  dsl_accessor :path_module do path_name.camelize end

  # The version attribute accessor for configuring the gem's version.
  #
  # This method sets up a DSL accessor for the version attribute, which
  # specifies the version number of the gem. It includes logic to determine the
  # version from the VERSION file or an environment variable override, and will
  # raise an ArgumentError if the version has not been set and cannot be
  # determined.
  #
  # @return [ String ] the version of the gem
  #
  # @raise [ ArgumentError ] if the version attribute has not been set and
  #                           cannot be read from the VERSION file or ENV override
  dsl_accessor :version do
    v = ENV['VERSION'].full? and next v
    File.read('VERSION').chomp
  rescue Errno::ENOENT
    has_to_be_set :version
  end

  # The version_epilogue attribute accessor for configuring additional content
  # to be appended to the version file.
  #
  # This method sets up a DSL accessor for the version_epilogue attribute,
  # which specifies extra content to be included at the end of the generated
  # version file. This can be useful for adding custom comments, license
  # information, or other supplementary data to the version module or class.
  #
  # @return [ String, nil ] the epilogue content or nil if not set
  dsl_accessor :version_epilogue

  # The post_install_message attribute accessor for configuring a message to
  # display after gem installation.
  #
  # This method sets up a DSL accessor for the post_install_message attribute,
  # which specifies a message to be displayed to users after the gem is installed.
  # This can be useful for providing additional information, usage instructions,
  # or important warnings to users of the gem.
  #
  # @return [ String, nil ] the post-installation message or nil if not set
  dsl_accessor :post_install_message

  # The required_ruby_version attribute accessor for configuring the minimum
  # Ruby version requirement.
  #
  # This method sets up a DSL accessor for the required_ruby_version attribute,
  # which specifies the minimum version of Ruby that the gem requires to run.
  # It allows defining the Ruby version constraint that will be included in the
  # gem specification.
  #
  # @return [ String, nil ] the required Ruby version string or nil if not set
  dsl_accessor :required_ruby_version

  # A class that encapsulates Ruby Version Manager (RVM) configuration settings
  # for a gem project.
  #
  # This class is responsible for managing RVM-specific configuration such as
  # the Ruby version to use and the gemset name. It provides a structured way
  # to define and access these settings within the context of a GemHadar
  # configuration.
  #
  # @example Configuring RVM settings
  #   GemHadar do
  #     rvm do
  #       use '3.0.0'
  #       gemset 'my_gem_dev'
  #     end
  #   end
  class RvmConfig
    extend DSLKit::DSLAccessor
    include DSLKit::BlockSelf

    # The initialize method sets up the RvmConfig instance by evaluating the
    # provided block in the context of the object.
    #
    # @param block [ Proc ] the block to be evaluated for configuring the RVM settings
    #
    # @return [ GemHadar::RvmConfig ] the initialized RvmConfig instance
    def initialize(&block)
      @outer_scope = block_self(&block)
      instance_eval(&block)
    end

    # The use method retrieves or sets the Ruby version to be used with RVM.
    #
    # This method serves as an accessor for the Ruby version configuration
    # within the RVM (Ruby Version Manager) settings. When called without
    # arguments, it returns the configured Ruby version. When called with
    # an argument, it sets the Ruby version to be used.
    #
    # @return [ String ] the Ruby version string configured for RVM use
    # @see GemHadar::RvmConfig
    dsl_accessor :use do `rvm tools strings`.split(/\n/).full?(:last) || 'ruby' end

    # The gemset method retrieves or sets the RVM gemset name for the project.
    #
    # This method serves as an accessor for the RVM (Ruby Version Manager)
    # gemset configuration within the nested RvmConfig class. When called
    # without arguments,
    # it returns the configured gemset name, which defaults to the gem's name.
    # When called with an argument, it sets the gemset name to be used with RVM.
    #
    # @return [ String ] the RVM gemset name configured for the project
    # @see GemHadar::RvmConfig#use
    # @see GemHadar::RvmConfig
    dsl_accessor :gemset do @outer_scope.name end
  end

  # The rvm method configures RVM (Ruby Version Manager) settings for the gem
  # project.
  #
  # This method initializes and returns an RvmConfig object that holds RVM-specific
  # configuration such as the Ruby version to use and the gemset name.
  # If a block is provided, it configures the RvmConfig object with the given
  # settings. If no block is provided and no existing RvmConfig object exists,
  # it creates a new one with default settings.
  #
  # @param block [ Proc ] optional block to configure RVM settings
  #
  # @return [ GemHadar::RvmConfig ] the RVM configuration object
  def rvm(&block)
    if block
      @rvm = RvmConfig.new(&block)
    elsif !@rvm
      @rvm = RvmConfig.new { }
    end
    @rvm
  end

  # The default_task_dependencies method manages the list of dependencies for
  # the default Rake task.
  #
  # This method sets up a DSL accessor for the default_task_dependencies
  # attribute, which specifies the sequence of Rake tasks that must be executed
  # when running the default task. These dependencies typically include
  # generating the gem specification and running tests to ensure a consistent
  # starting point for development workflows.
  #
  # @return [ Array<Symbol, String> ] an array of task names that are required
  #                                   as dependencies for the default task execution
  dsl_accessor :default_task_dependencies, [ :gemspec, :test ]

  # The default_task method defines the default Rake task for the gem project.
  #
  # This method sets up a Rake task named :default that depends on the tasks
  # specified in the default_task_dependencies accessor. It provides a convenient
  # way to run the most common or essential tasks for the project with a single
  # command.
  def default_task
    desc 'Default task'
    task :default => default_task_dependencies
  end

  # The build_task_dependencies method manages the list of dependencies for the
  # build task.
  #
  # This method sets up a DSL accessor for the build_task_dependencies
  # attribute, which specifies the sequence of Rake tasks that must be executed
  # when running the build task. These dependencies typically include cleaning
  # previous builds, generating the gem specification, packaging the gem, and
  # creating a version tag.
  #
  # @return [ Array<Symbol, String> ] an array of task names that are required
  #                                   as dependencies for the build task execution
  dsl_accessor :build_task_dependencies, [ :clobber, :gemspec, :package, :'version:tag' ]

  # The build_task method defines a Rake task that orchestrates the complete
  # build process for packaging the gem.
  #
  # This method sets up a :build task that depends on the tasks specified in
  # the build_task_dependencies accessor. It provides a convenient way to
  # execute all necessary steps for building packages for a release with a
  # single command.
  def build_task
    desc 'Build task (builds all packages for a release)'
    task :build => build_task_dependencies
  end

  # The install_library method sets up a Rake task for installing the library
  # or executable into site_ruby directories.
  #
  # This method configures an :install task that depends on the
  # :prepare_install task and executes the provided block. It stores the block
  # in an instance variable to be called later when the task is executed.
  #
  # @param block [ Proc ] the block containing the installation logic
  def install_library(&block)
    @install_library_block = -> do
      desc 'Install executable/library into site_ruby directories'
      task :install => :prepare_install, &block
    end
  end

  # The clean method manages the CLEAN file list for Rake tasks.
  #
  # When called without arguments, it returns the current CLEAN file list.
  # When called with arguments, it adds the specified files to the CLEAN list.
  #
  # @param args [ Array<String> ] optional list of files to add to the CLEAN list
  #
  # @return [ FileList, nil ] the CLEAN file list when no arguments provided,
  #                           nil otherwise
  def clean(*args)
    if args.empty?
      CLEAN
    else
      CLEAN.include(*args)
    end
  end

  # The clobber method manages the CLOBBER file list for Rake tasks.
  #
  # When called without arguments, it returns the current CLOBBER file list.
  # When called with arguments, it adds the specified files to the CLOBBER list.
  #
  # @param args [ Array<String> ] optional list of files to add to the CLOBBER list
  #
  # @return [ FileList, nil ] the CLOBBER file list when no arguments provided,
  #                           nil otherwise
  def clobber(*args)
    if args.empty?
      CLOBBER
    else
      CLOBBER.include(*args)
    end
  end

  # The ignore method manages the list of files to be ignored by the gem.
  #
  # When called without arguments, it returns the current set of ignored files.
  # When called with arguments, it adds the specified files to the ignore list.
  #
  # @param args [ Array<String> ] optional list of file patterns to add to the ignore list
  #
  # @return [ Set<String>, nil ] the set of ignored files when no arguments provided,
  #                           nil otherwise
  def ignore(*args)
    if args.empty?
      ignore_files
    else
      args.each { |a| ignore_files << a }
    end
  end

  # The package_ignore method manages the list of files to be ignored during
  # gem packaging.
  #
  # When called without arguments, it returns the current set of package ignore
  # files. When called with arguments, it adds the specified file patterns to
  # the package ignore list.
  #
  # @param args [ Array<String> ] optional list of file patterns to add to the package ignore list
  #
  # @return [ Set<String>, nil ] the set of package ignore files when no arguments provided,
  #                           nil otherwise
  def package_ignore(*args)
    if args.empty?
      package_ignore_files
    else
      args.each { |a| package_ignore_files << a }
    end
  end

  # The dependency method adds a new runtime dependency to the gem.
  #
  # @param args [ Array ] the arguments defining the dependency
  def dependency(*args)
    @dependencies << args
  end

  # The development_dependency method adds a new development-time dependency to
  # the gem.
  #
  # @param args [ Array ] the arguments defining the development dependency
  def development_dependency(*args)
    @development_dependencies << args
  end

  # The gems_install_task method defines a Rake task for installing all gem
  # dependencies specified in the Gemfile.
  #
  # This method sets up a :gems:install task that executes a block to install
  # gems. If no block is provided, it defaults to running 'bundle install'.
  #
  # @param block [ Proc ] optional block containing the installation command
  def gems_install_task(&block)
    block ||= proc {  sh 'bundle install' }
    desc 'Install all gems from the Gemfile'
    namespace :gems do
      task :install => :gemspec , &block
    end
  end

  # The version_task method defines a Rake task that generates a version file
  # for the gem.
  #
  # This method creates a task named :version that writes version information
  # to a Ruby file in the lib directory. The generated file contains constants
  # for the version and its components, as well as an optional epilogue
  # section. The task ensures the target directory exists and uses secure file
  # writing to prevent permission issues.
  def version_task
    desc m = "Writing version information for #{name}-#{version}"
    task :version do
      puts m
      mkdir_p dir = File.join('lib', path_name)
      secure_write(File.join(dir, 'version.rb')) do |v|
        v.puts <<~EOT
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

  # The version_show_task method defines a Rake task that displays the current
  # version of the gem.
  #
  # This method creates a :version:show task under the Rake namespace that
  # reads the version from the generated version file in the lib directory and
  # compares it with the version specified in the GemHadar configuration. It
  # then outputs a message indicating whether the versions match or not.
  def version_show_task
    namespace :version do
      desc "Displaying the current version"
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

  # The version_log_diff method generates a git log output containing patch
  # differences between two specified versions.
  #
  # This method retrieves the commit history between a starting version and an
  # ending version, including detailed changes (patch format) for each commit.
  # It supports comparing against the current HEAD or specific version tags,
  # and automatically determines the appropriate previous version when only a
  # target version is provided.
  #
  # @param to_version [ String ] the ending version tag or 'HEAD' to compare up to the latest commit
  # @param from_version [ String, nil ] the starting version tag; if nil, it defaults based on to_version
  #
  # @raise [ RuntimeError ] if the specified version tags are not found in the repository
  #
  # @return [ String ] the git log output in patch format showing changes between the two versions
  def version_log_diff(to_version: 'HEAD', from_version: nil)
    if to_version == 'HEAD'
      if from_version.blank?
        from_version = versions.last
      else
        unless versions.find { |v| v == from_version }
          fail "Could not find #{from_version.inspect}."
        end
      end
      `git log -p #{version_tag(from_version)}..HEAD`
    else
      unless versions.find { |v| v == to_version }
        fail "Could not find #{to_version.inspect}."
      end
      if from_version.blank?
        from_version = versions.each_cons(2).find do |previous_version, v|
          if v == to_version
            break previous_version
          end
        end
        unless from_version
          return `git log -p #{version_tag(to_version)}`
        end
      else
        unless versions.find { |v| v == from_version }
          fail "Could not find #{from_version.inspect}."
        end
      end
      `git log -p #{version_tag(from_version)}..#{version_tag(to_version)}`
    end
  end

  # The version_diff_task method defines Rake tasks for listing and displaying
  # git version differences.
  #
  # This method sets up two subtasks under the :version namespace:
  #
  # - A :list task that fetches all git tags, ensures the operation succeeds,
  # and outputs the sorted list of versions.
  # - A :diff task that calculates the version range, displays a colored diff
  # between the versions, and shows the changes.
  def version_diff_task
    namespace :version do
      desc "List all versions in order"
      task :list do
        system 'git fetch --tags'
        $?.success? or exit $?.exitstatus
        puts versions
      end

      desc "Displaying the diff from env var VERSION to the next version or HEAD"
      task :diff do
        start_version, end_version = determine_version_range
        puts color(172) { "Showing diff from version %s to %s:" % [ start_version, end_version ] }
        puts `git diff --color=always #{start_version}..#{end_version}`
      end
    end
  end

  # The gem_hadar_update_task method defines a Rake task that updates the
  # gem_hadar dependency version in the gemspec file.
  #
  # This method creates a :gem_hadar:update task under the Rake namespace that
  # prompts the user to specify a new gem_hadar version.
  # It then reads the existing gemspec file, modifies the version constraint
  # for the gem_hadar dependency, and writes the updated content back to the
  # file. If the specified version is already present in the gemspec, it skips
  # the update and notifies the user.
  def gem_hadar_update_task
    namespace :gem_hadar do
      desc 'Update gem_hadar to a different version'
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

  # The gemspec_task method defines a Rake task that generates and writes a
  # gemspec file for the project.
  #
  # This method creates a :gemspec task that depends on the :version task,
  # ensuring the version is set before generating the gemspec. It constructs
  # the filename based on the project name, displays a warning message
  # indicating the file being written, and uses secure_write to create the
  # gemspec file with content generated by the gemspec method.
  def gemspec_task
    desc 'Create a gemspec file'
    task :gemspec => :version do
      filename = "#{name}.gemspec"
      warn "Writing to #{filename.inspect} for #{version}"
      secure_write(filename, gemspec.to_ruby)
    end
  end

  # The package_task method sets up a Rake task for packaging the gem.
  #
  # This method configures a task that creates a package directory, initializes
  # a Gem::PackageTask with the current gem specification, and specifies that
  # tar files should be created. It also includes the files to be packaged by
  # adding gem_files to the package_files attribute of the Gem::PackageTask.
  def package_task
    clean 'pkg'
    Gem::PackageTask.new(gemspec) do |pkg|
      pkg.need_tar      = true
      pkg.package_files += gem_files
    end
  end

  # The install_library_task method executes the installed library task block
  # if it has been defined.
  def install_library_task
    @install_library_block.full?(:call)
  end

  # The test_task method sets up a Rake task for executing the project's test
  # suite.
  #
  # This method configures a Rake task named :test that runs the test suite
  # using Rake::TestTask. It includes the test directory and required paths in
  # the load path, specifies the test files to run, and enables verbose output.
  # The task also conditionally depends on the :compile task if project
  # extensions are present.
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

  # The spec_task method sets up a Rake task for executing RSpec tests.
  #
  # This method configures a :spec task that runs the project's RSpec test
  # suite. It initializes an RSpec::Core::RakeTask with appropriate Ruby
  # options, test pattern, and verbose output. The task also conditionally
  # depends on the :compile task if project extensions are present.
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

  # The rcov_task method sets up a Rake task for executing code coverage tests
  # using RCov.
  #
  # This method configures a :rcov task that runs the project's test suite with
  # RCov to generate code coverage reports. It includes the test directory and
  # required paths in the load path, specifies the test files to run, and
  # enables verbose output. The task also conditionally depends on the :compile
  # task if project extensions are present. If RCov is not available, it
  # displays a warning message suggesting to install RCov.
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

  # The version_bump_task method defines Rake tasks for incrementing the gem's
  # version number.
  #
  # This method sets up a hierarchical task structure under the :version
  # namespace:
  #
  # - It creates subtasks in the :version:bump namespace for explicitly bumping
  # major, minor, or build versions.
  # - It also defines a :version:bump task that automatically suggests the
  # appropriate version bump type by analyzing recent changes using AI. The
  # suggestion is based on the git log diff between the previous version and
  # the current HEAD, and it prompts the user for confirmation before applying
  # the bump.
  #
  # The tasks utilize the version_log_diff method to gather change information,
  # the ollama_generate method to get AI-powered suggestions, and the
  # version_bump_to method to perform the actual version update.
  def version_bump_task
    namespace :version do
      namespace :bump do
        desc 'Bump major version'
        task :major do
          version_bump_to(:major)
        end

        desc 'Bump minor version'
        task :minor do
          version_bump_to(:minor)
        end

        desc 'Bump build version'
        task :build do
          version_bump_to(:build)
        end
      end

      desc 'Bump version with AI suggestion'
      task :bump do
        log_diff = version_log_diff(from_version: nil, to_version: 'HEAD')
        system   = xdg_config('version_bump_system_prompt.txt', default_version_bump_system_prompt)
        prompt   = xdg_config('version_bump_prompt.txt', default_version_bump_prompt) % { version:, log_diff: }
        response = ollama_generate(system:, prompt:)
        puts response
        default = nil
        if response =~ /(major|minor|build)\s*$/
          default = $1
        end
        response = ask?(
          'Bump a major, minor, or build version%{default}? ',
          /\A(major|minor|build)\z/,
          default:
        )
        if version_type = response&.[](1)
          version_bump_to(version_type)
        else
          exit 1
        end
      end
    end
  end

  # The version_tag_task method defines a Rake task that creates a Git tag for
  # the current version.
  #
  # This method sets up a :version:tag task under the Rake namespace that
  # creates an annotated Git tag for the project's current version. It checks
  # if a tag with the same name already exists and handles the case where the
  # tag exists but is different from the current commit. If the tag already
  # exists and is different, it prompts the user to confirm whether to
  # overwrite it forcefully.
  def version_tag_task
    namespace :version do
      desc "Tag this commit as version #{version}"
      task :tag do
        force = ENV['FORCE'].to_i == 1
        begin
          sh "git tag -a -m 'Version #{version}' #{'-f' if force} #{version_tag(version)}"
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

  # The git_remote method retrieves the primary Git remote name configured for
  # the project.
  #
  # It first checks the GIT_REMOTE environment variable for a custom remote
  # specification. If not set, it defaults to 'origin'. When multiple remotes
  # are specified in the environment variable, only the first one is returned.
  def git_remote
    ENV.fetch('GIT_REMOTE', 'origin').split(/\s+/).first
  end

  # The master_prepare_task method defines a Rake task that sets up a remote
  # Git repository for the project.
  #
  # This method creates a :master:prepare task under the Rake namespace that
  # guides the user through creating a new bare Git repository on a remote
  # server via SSH. It prompts for the remote name, directory path, and SSH
  # account details to configure the repository and establish a connection back
  # to the local project.
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

  # The version_push_task method defines Rake tasks for pushing version tags to
  # Git remotes.
  #
  # This method sets up a hierarchical task structure under the :version
  # namespace:
  #
  # - It creates subtasks in the :version:push namespace for each configured
  # Git remote, allowing individual pushes to specific remotes.
  # - It also defines a top-level :version:push task that depends on all the
  # individual remote push tasks, enabling a single command to push the version
  # tag to all remotes.
  #
  # The tasks utilize the git_remotes method to determine which remotes are
  # configured and generate appropriate push commands for each one.
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

  # The master_push_task method defines Rake tasks for pushing the master
  # branch to configured Git remotes.
  #
  # This method sets up a hierarchical task structure under the :master namespace:
  #
  # - It creates subtasks in the :master:push namespace for each configured Git
  #   remote, allowing individual pushes to specific remotes.
  # - It also defines a top-level :master:push task that depends on all the individual
  #   remote push tasks, enabling a single command to push the master branch to
  #   all remotes.
  #
  # The tasks utilize the git_remotes method to determine which remotes are
  # configured and generate appropriate push commands for each one.
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

  # The gem_push_task method defines a Rake task for pushing the generated gem
  # file to RubyGems.
  #
  # This method sets up a :gem:push task under the Rake namespace that handles
  # the process of uploading the gem package to RubyGems. It checks if the
  # project is in developing mode and skips the push operation if so.
  # Otherwise, it verifies the existence of the gem file, prompts the user for
  # confirmation before pushing, and uses the gem push command with an optional
  # API key from the environment. If the gem file does not exist or the user
  # declines to push, appropriate messages are displayed and the task exits
  # accordingly.
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
              key = ENV['GEM_HOST_API_KEY'].full? { |k| "--key #{k} " }
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

  # The git_remotes_task method defines a Rake task that displays all Git
  # remote repositories configured for the project.
  #
  # This method sets up a :git_remotes task under the Rake namespace that
  # retrieves and prints the list of Git remotes along with their URLs. It uses
  # the git_remotes method to obtain the remote names and then fetches each
  # remote's URL using the `git remote get-url` command. The output is
  # formatted to show each remote name followed by its corresponding URL on
  # separate lines.
  def git_remotes_task
    task :git_remotes do
      puts git_remotes.map { |r|
        url = `git remote get-url #{r.inspect}`.chomp
        "#{r} #{url}"
      }
    end
  end

  # The create_git_release_body method generates a changelog for a GitHub
  # release by analyzing the git diff between the previous version and the
  # current HEAD.
  #
  # It retrieves the log differences, fetches or uses default system and prompt
  # templates, and utilizes an AI model to produce a formatted changelog entry.
  #
  # @return [ String ] the generated changelog content for the release body
  def create_git_release_body
    log_diff = version_log_diff(to_version: version)
    system   = xdg_config('release_system_prompt.txt', default_git_release_system_prompt)
    prompt   = xdg_config('release_prompt.txt', default_git_release_prompt) % { name:, version:, log_diff: }
    ollama_generate(system:, prompt:)
  end

  # The github_release_task method defines a Rake task that creates a GitHub
  # release for the current version.
  #
  # This method sets up a :github:release task that prompts the user to confirm
  # publishing a release message on GitHub. It retrieves the GitHub API token
  # from the environment, derives the repository owner and name from the git
  # remote URL, generates a changelog using AI, and creates the release via the
  # GitHub API.
  def github_release_task
    namespace :github do
      unless github_api_token = ENV['GITHUB_API_TOKEN'].full?
        warn "GITHUB_API_TOKEN not set. => Skipping github release task."
        task :release
        return
      end
      desc "Create a new GitHub release for the current version with a AI-generated changelog"
      task :release do
        yes = ask?(
          "Do you want to publish a release message on github? (y/n%{default}) ",
          /\Ay/i, default: ENV['GITHUB_RELEASE_ENABLED']
        )
        unless yes
            warn "Skipping publication of a github release message."
            next
        end
        if %r(\A/*(?<owner>[^/]+)/(?<repo>[^/.]+)) =~ github_remote_url&.path
          rc = GitHub::ReleaseCreator.new(owner:, repo:, token: github_api_token)
          tag_name         = version_tag(version)
          target_commitish = `git show -s --format=%H #{tag_name.inspect}^{commit}`.chomp
          body             = edit_temp_file(create_git_release_body)
          if body.present?
            begin
              response = rc.perform(tag_name:, target_commitish:, body:)
              puts "Release created successfully! See #{response.html_url}"
            rescue => e
              warn e.message
            end
          else
            warn "Skipping creation of github release message."
          end
        else
          warn "Could not derive github remote url from git remotes. => Skipping github release task."
        end
      end
    end
  end

  # The push_task_dependencies method manages the list of dependencies for the push task.
  #
  # This method sets up a DSL accessor for the push_task_dependencies attribute,
  # which specifies the sequence of Rake tasks that must be executed when running
  # the push task. These dependencies typically include checks for modified files,
  # building the gem, pushing to remote repositories, and publishing to package
  # managers like RubyGems and GitHub.
  #
  # @return [ Array<Symbol, String> ] an array of task names that are required
  #                                   as dependencies for the push task execution
  dsl_accessor :push_task_dependencies, %i[ modified build master:push version:push gem:push github:release ]

  # The push_task method defines a Rake task that orchestrates the complete
  # process of pushing changes and artifacts to remote repositories and package
  # managers.
  #
  # This method sets up multiple subtasks including preparing the master
  # branch, pushing version tags, pushing to gem repositories, and creating
  # GitHub releases. It also includes a check for uncommitted changes before
  # proceeding with the push operations.
  def push_task
    master_prepare_task
    version_push_task
    master_push_task
    gem_push_task
    git_remotes_task
    github_release_task
    task :modified do
      changed_files = `git status --porcelain`.gsub(/^\s*\S\s+/, '').lines
      unless changed_files.empty?
        warn "There are still modified files:\n#{changed_files * ''}"
        exit 1
      end
    end
    desc "Push all changes for version #{version} into the internets."
    task :push => push_task_dependencies
  end

  # The release_task method defines a Rake task that orchestrates the complete
  # release process for the gem.
  #
  # This method sets up a :release task that depends on the :push task,
  # ensuring all necessary steps for publishing the gem are executed in
  # sequence. It provides a convenient way to perform a full release workflow
  # with a single command.
  def release_task
    desc "Release the new version #{version} for the gem #{name}."
    task :release => :push
  end

  # The compile_task method sets up a Rake task to compile project extensions.
  #
  # This method creates a :compile task that iterates through the configured
  # extensions and compiles them using the system's make command.
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

  # The rvm_task method creates a .rvmrc file that configures RVM to use the
  # specified Ruby version and gemset for the project.
  #
  # This task generates a .rvmrc file in the project root directory with commands to:
  # - Use the Ruby version specified by the rvm.use accessor
  # - Create the gemset specified by the rvm.gemset accessor
  # - Switch to using that gemset
  #
  # The generated file is written using the secure_write method to ensure
  # proper file permissions.
  def rvm_task
    desc 'Create .rvmrc file'
    task :rvm do
      secure_write('.rvmrc') do |output|
        output.write <<~EOT
          rvm use #{rvm.use}
          rvm gemset create #{rvm.gemset}
          rvm gemset use #{rvm.gemset}
        EOT
      end
    end
  end

  def yard_doc_task
    YARD::Rake::YardocTask.new(:yard_doc) do |t|
      t.files = doc_code_files.select { _1 =~ /\.rb\z/ }

      output_dir = yard_dir
      t.options = [ "--output-dir=#{output_dir}" ]

      # Include private & protected methods in documentation
      t.options << '--private' << '--protected'

      # Handle readme if present
      if readme && File.exist?(readme)
        t.options << "--readme=#{readme}"
      end

      # Add additional documentation files
      if doc_files&.any?
        t.files.concat(doc_files.flatten)
      end

      # Add before hook for cleaning
      t.before = proc {
        clean output_dir
        puts "Generating full documentation in #{output_dir}..."
      }
    end
  end

  # The yard_task method sets up and registers Rake tasks for generating and
  # managing YARD documentation.
  #
  # It creates multiple subtasks under the :yard namespace, including tasks for
  # creating private documentation, viewing the generated documentation,
  # cleaning up documentation files, and listing undocumented elements.
  # If YARD is not available, the method returns early without defining any tasks.
  def yard_task
    defined? YARD or return
    yard_doc_task
    desc 'Create yard documentation (including private)'
    task :doc => :yard_doc
    namespace :yard do
      my_yard_dir = Pathname.new(yard_dir)

      task :private => :yard_doc

      task :public => :yard_doc

      desc 'Create yard documentation'
      task :doc => :yard_doc

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

  def config_task
    namespace :gem_hadar do
      desc "Display current gem_hadar configuration"
      task :config do
        puts "=== GemHadar Configuration ==="

        # RubyGems
        if ENV['GEM_HOST_API_KEY'].present?
          puts "RubyGems API Key: *** (set)"
        else
          puts "RubyGems API Key: Not set"
        end

        # GitHub
        if ENV['GITHUB_API_TOKEN'].present?
          puts "GitHub API Token: *** (set)"
        else
          puts "GitHub API Token: Not set"
        end

        # Ollama
        puts "Ollama Model: #{ollama_model} (default is #{ollama_model_default})"

        if url = ollama_client&.full?(:base_url)&.to_s
          puts "Ollama Base URL: #{url.inspect}"
        else
          puts "Ollama Base URL: Not set"
        end

        if ENV['OLLAMA_MODEL_OPTIONS']
          puts "Ollama Model Options: #{ENV['OLLAMA_MODEL_OPTIONS']}"
        else
          puts "Ollama Model Options: Not set (using defaults)"
        end

        # XDG config home
        puts "XDG config home: #{xdg_config_home.to_s.inspect}"

        # General
        puts "Gem Name: #{name}"
        puts "Version: #{version}"

        # Build/Development
        puts "MAKE: #{ENV['MAKE'] || 'Not set (will use gmake or make)'}"
        puts "EDITOR: #{ENV['EDITOR'] || 'Not set (will use vi)'}"

        # Git
        puts "Git Remote(s): #{ENV['GIT_REMOTE'] || 'origin'}"

        # Other
        puts "Force Operations: #{ENV['FORCE'] || '0'}"
        puts "Version Override: #{ENV['VERSION'] || 'Not set'}"
        puts "GitHub Release Enabled: #{ENV['GITHUB_RELEASE_ENABLED'] || 'Not set'}"

        puts "\n=== AI Prompt Configuration (Default Values) ==="
        arrow = ?⤵
        puts bold{"version_bump_system_prompt.txt"} + "#{arrow}\n" + italic{default_version_bump_system_prompt}
        puts bold{"version_bump_prompt.txt"} + "#{arrow}\n#{default_version_bump_prompt}"
        puts bold{"release_system_prompt.txt"} + "#{arrow}\n" + italic{default_git_release_system_prompt}
        puts bold{"release_prompt.txt"} + "#{arrow}\n" + italic{default_git_release_prompt}

        puts "=== End Configuration ==="
      end
    end
  end

  # The create_all_tasks method sets up and registers all the Rake tasks for
  # the gem project.
  #
  # @return [GemHadar] the instance of GemHadar
  def create_all_tasks
    default_task
    config_task
    build_task
    rvm_task
    version_task
    version_show_task
    version_diff_task
    gem_hadar_update_task
    gemspec_task
    gems_install_task
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
    release_task
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

  # The edit_temp_file method creates a temporary file with the provided
  # content, opens it in an editor for user modification, and returns the
  # updated content.
  #
  # This method first determines the editor to use from the EDITOR environment
  # variable or defaults to vi. If the editor cannot be found, it issues a
  # warning and returns nil. It then creates a temporary file, writes the
  # initial content to it, and opens the file in the editor. After the user
  # saves and closes the editor, it reads the modified content from the
  # temporary file. The temporary file is automatically cleaned up after use.
  #
  # @param content [ String ] the initial content to write to the temporary
  # file
  #
  # @return [ String, nil ] the content of the temporary file after editing, or
  # nil if the editor could not be found or failed
  def edit_temp_file(content)
    editor = ENV.fetch('EDITOR', `which vi`.chomp)
    unless File.exist?(editor)
      warn "Can't find EDITOR. => Returning."
      return
    end
    temp_file = Tempfile.new(%w[ changelog .md ])
    temp_file.write(content)
    temp_file.close

    unless system("#{editor} #{temp_file.path}")
      warn "#{editor} returned #{$?.exitstatus} => Returning."
      return
    end

    File.read(temp_file.path)
  ensure
    temp_file&.close&.unlink
  end

  # The ollama_model_default method returns the default name of the Ollama AI
  # model to be used for generating responses when no custom model is
  # specified.
  #
  # @return [ String ] the default Ollama AI model name, which is 'llama3.1'
  dsl_accessor :ollama_model_default, 'llama3.1'.freeze

  # The ollama_model method retrieves the name of the Ollama AI model to be
  # used for generating responses.
  #
  # It first checks the OLLAMA_MODEL environment variable for a custom model
  # specification. If the environment variable is not set, it falls back to
  # using the default model name, which is determined by the
  # ollama_model_default dsl method.
  #
  # @return [ String ] the name of the Ollama AI model to be used
  def ollama_model
    ENV.fetch('OLLAMA_MODEL', ollama_model_default)
  end

  # The ollama_client method creates and returns an Ollama::Client instance
  # configured with a base URL derived from environment variables.
  #
  # It first checks for the OLLAMA_URL environment variable to determine the
  # base URL. If that is not set, it falls back to using the OLLAMA_HOST
  # environment variable, defaulting to 'localhost:11434' if that is also not
  # set. The method then constructs the full base URL and initializes an
  # Ollama::Client with appropriate timeouts for read and connect operations.
  #
  # @return [Ollama::Client, nil] An initialized Ollama::Client instance if a valid base URL is present, otherwise nil.
  def ollama_client
    base_url = ENV['OLLAMA_URL']
    if base_url.blank?
      host = ENV.fetch('OLLAMA_HOST', 'localhost:11434')
      base_url = 'http://%s' % host
    end
    base_url.present? or return
    Ollama::Client.new(base_url:, read_timeout: 600, connect_timeout: 60)
  end

  # Generates a response from an AI model using the Ollama::Client.
  #
  # @param [String] system The system prompt for the AI model.
  # @param [String] prompt The user prompt to generate a response to.
  # @return [String, nil] The generated response or nil if generation fails.
  def ollama_generate(system:, prompt:)
    unless ollama = ollama_client
      warn "Ollama is not configured. => Returning."
      return
    end
    model    = ollama_model
    options  = ENV['OLLAMA_MODEL_OPTIONS'].full? { |o| JSON.parse(o) } || {}
    options |= { "temperature" => 0, "top_p" => 1, "min_p" => 0.1 }
    ollama.generate(model:, system:, prompt:, options:, stream: false, think: false).response
  end

  # Increases the specified part of the version number and writes it back to
  # the VERSION  file.
  #
  # @param [Symbol, String] type The part of the version to bump (:major, :minor, or :build)
  def version_bump_to(type)
    type    = type.to_sym
    version = File.read('VERSION').chomp.version
    version.bump(type)
    secure_write('VERSION') { |v| v.puts version }
    exit 0
  end

  # Determine the start and end versions for diff comparison.
  #
  # If the VERSION env var is set, it will be used as the starting version tag.
  # Otherwise, it defaults to the current commit's version or the latest tag.
  #
  # @return [Array(String, String)] A fixed-size array containing:
  #   - The start version (e.g., '1.2.3') from which changes are compared.
  #   - The end version (e.g., '1.2.4' or 'HEAD') up to which changes are compared.
  def determine_version_range
    version_tags = versions.map { version_tag(_1) } + %w[ HEAD ]
    found_version_tag = version_tags.index(version_tag(version))
    found_version_tag.nil? and fail "cannot find version tag #{version_tag(version)}"
    start_version, end_version = version_tags[found_version_tag, 2]
    return start_version, end_version
  end

  # The write_ignore_file method writes the current ignore_files configuration
  # to a .gitignore file in the project root directory.
  def write_ignore_file
    secure_write('.gitignore') do |output|
      output.puts(ignore.sort)
    end
  end

  # The write_gemfile method creates and writes the default Gemfile content if
  # it doesn't exist. If a custom Gemfile exists, it only displays a warning.
  def write_gemfile
    default_gemfile =<<~EOT
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

  # The assert_valid_link method verifies that the provided URL is valid by
  # checking if it returns an HTTP OK status after following redirects, unless
  # project is still `developing`.
  #
  # @param name [String] the name associated with the link being validated
  # @param orig_url [String] the URL to validate
  #
  # @return [String] the original URL if validation succeeds
  #
  # @raise [ArgumentError] if the final response is not an HTTP OK status after
  # following redirects
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

  # The gemspec method creates and returns a new Gem::Specification object
  # that defines the metadata and dependencies for the gem package.
  #
  # @return [Gem::Specification] a fully configured Gem specification object
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
      s.add_development_dependency('gem_hadar', "~> #{VERSION[/\A\d+\.\d+/, 0]}")
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
        if File.exist?(readme)
          s.rdoc_options << '--main' << readme
          s.extra_rdoc_files << readme
        else
          warn "Add a #{readme} file to document your gem!"
        end
      end
      doc_files.full? { |df| s.extra_rdoc_files.concat Array(df) }
    end
  end

  # The git_remotes method retrieves the list of remote repositories configured
  # for the current Git project.
  #
  # It first attempts to read the remotes from the ENV['GIT_REMOTE']
  # environment variable, splitting it by whitespace. If this is not available,
  # it falls back to querying the local Git repository using `git remote`.
  #
  # @return [ Array<String> ] an array of remote names
  def git_remotes
    remotes = ENV['GIT_REMOTE'].full?(:split, /\s+/)
    remotes or remotes = `git remote`.lines.map(&:chomp)
    remotes
  end

  # The ask? method prompts the user with a message and reads their input It
  # returns a MatchData object if the input matches the provided pattern.
  #
  # @param prompt [ String ] the message to display to the user
  # @param pattern [ Regexp ] the regular expression to match against the input
  #
  # @return [ MatchData, nil ] the result of the pattern match or nil if no match
  def ask?(prompt, pattern, default: nil)
    if prompt.include?('%{default}')
      if default.present?
        prompt = prompt % { default: ", default is #{default.inspect}" }
      else
        prompt = prompt % { default: '' }
      end
    end
    STDOUT.print prompt
    answer = STDIN.gets.chomp
    default.present? && answer.blank? and answer = default
    if answer =~ pattern
      $~
    end
  end

  # The gem_files method returns an array of files that are included in the gem
  # package.
  #
  # It calculates this by subtracting the files listed in package_ignore_files
  # from the list of all files.
  #
  # @return [ Array<String> ] the list of files to include in the gem package
  def gem_files
    (files.to_a - package_ignore_files.to_a)
  end

  # The versions method retrieves and processes the list of git tags that match
  # semantic versioning patterns.
  #
  # It executes `git tag` to get all available tags, filters them using a
  # regular expression to identify valid version strings, removes any 'v'
  # prefix from each version string, trims whitespace, and sorts the resulting
  # array based on semantic versioning order.
  #
  # @return [ Array<String> ] an array of version strings sorted in ascending
  # order according to semantic versioning rules.
  memoize method:
  def versions
    `git tag`.lines.grep(/^v?\d+\.\d+\.\d+$/).map(&:chomp).map {
      _1.sub(/\Av/, '')
    }.sort_by(&:version)
  end

  # The version_tag method prepends a 'v' prefix to the given version
  # string, unless it's HEAD.
  #
  # @param version [String] the version string to modify
  # @return [String] the modified version string with a 'v' prefix
  def version_tag(version)
    if version != 'HEAD'
      version.dup.prepend ?v
    else
      version.dup
    end
  end

  # The version_untag method removes the 'v' prefix from a version tag string.
  #
  # @param version_tag [ String ] the version tag string that may start with 'v'
  #
  # @return [ String ] the version string with the 'v' prefix removed
  def version_untag(version_tag)
    version.sub(/\Av/, '')
  end

  # The github_remote_url method retrieves and parses the GitHub remote URL
  # from the local Git configuration.
  #
  # It executes `git remote -v` to get all remote configurations, extracts the
  # push URLs, processes them to construct valid URIs, and returns the first
  # URI pointing to GitHub.com.
  #
  # @return [URI, nil] The parsed GitHub remote URI or nil if not found.
  def github_remote_url
    if remotes = `git remote -v`
      remotes_urls = remotes.scan(/^(\S+)\s+(\S+)\s+\(push\)/)
      remotes_uris = remotes_urls.map do |name, url|
        if %r(\A(?<scheme>[^@]+)@(?<hostname>[A-Za-z0-9.]+):(?:\d*)(?<path>.*)) =~ url
          path = ?/ + path unless path.start_with? ?/
          url = 'ssh://%s@%s%s' % [ scheme, hostname, path ] # approximate correct URIs
        end
        URI.parse(url)
      end
      remotes_uris.find { |uri| uri.hostname == 'github.com' }
    end
  end
end

# The GemHadar method serves as the primary entry point for configuring and
# initializing a gem project using the GemHadar framework.
#
# This method creates a new instance of the GemHadar class, passes the provided
# block to configure the gem settings, and then invokes the create_all_tasks
# method to set up all the necessary Rake tasks for the project.
#
# @param block [ Proc ] a configuration block used to define gem properties and settings
#
# @return [ GemHadar ] the configured GemHadar instance after all tasks have been created
def GemHadar(&block)
  GemHadar.new(&block).create_all_tasks
end

# The template method processes an ERB template file and creates a Rake task
# for its compilation.
#
# This method takes a template file path, removes its extension to determine
# the output file name, and sets up a Rake file task that compiles the template
# using the provided block configuration. It ensures the source file has an
# extension and raises an error if not.
#
# @param pathname [ String ] the path to the template file to be processed
#
# @yield [ block ] the configuration block for the template compiler
#
# @return [ Pathname ] the Pathname object representing the destination file path
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
