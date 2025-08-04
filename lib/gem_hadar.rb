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
class GemHadar
end
require 'gem_hadar/version'
require 'gem_hadar/setup'
require 'gem_hadar/template_compiler'
require 'gem_hadar/github'

class GemHadar
  include Term::ANSIColor

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
    v = ENV['VERSION'].full? and next v
    File.read('VERSION').chomp
  rescue Errno::ENOENT
    has_to_be_set :version
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
    @install_library_block = -> do
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
          fail "Could not find version before #{to_version.inspect}."
        end
      else
        unless versions.find { |v| v == from_version }
          fail "Could not find #{from_version.inspect}."
        end
      end
      `git log -p #{version_tag(from_version)}..#{version_tag(to_version)}`
    end
  end

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
        version_tags = versions.map { version_tag(_1) } + %w[ HEAD ]
        found_version_tag = version_tags.index(version_tag(version))
        found_version_tag.nil? and fail "cannot find version tag #{version_tag(version)}"
        start_version, end_version = version_tags[found_version_tag, 2]
        puts color(172) { "Showing diff from version %s to %s:" % [ start_version, end_version ] }
        puts `git diff --color=always #{start_version}..#{end_version}`
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
    clean 'pkg'
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

  def git_remote
    ENV.fetch('GIT_REMOTE', 'origin').split(/\s+/).first
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

  def git_remotes_task
    task :git_remotes do
      puts git_remotes.map { |r|
        url = `git remote get-url #{r.inspect}`.chomp
        "#{r} #{url}"
      }
    end
  end

  def create_git_release_body
    base_url = ENV['OLLAMA_URL']
    if base_url.blank? && host = ENV['OLLAMA_HOST'].full?
      base_url = 'http://%s' % host
    end
    base_url.present? or return
    log_diff = version_log_diff(to_version: version)
    model    = ENV.fetch('OLLAMA_MODEL', 'llama3.1')
    ollama   = Ollama::Client.new(base_url:, read_timeout: 600, connect_timeout: 60)
    system = <<~EOT
      You are a Ruby programmer generating changelog messages in markdown
      format for new releases, so users can see what has changed. Remember you
      are not a chatbot of any kind.
    EOT
    prompt = (<<~EOT) % { name:, version:, log_diff: }
      Output the content of a changelog for the new release of %{name} %{version}

      **Strictly** follow these guidelines:

        - Use bullet points in markdown format (`-`) to list significant changes.
        - Exclude trivial updates such as:
          * Version number increments
          * Dependency version bumps (unless they resolve critical issues)
          * Minor code style adjustments
          * Internal documentation tweaks
        - Include only verified and substantial changes that impact
          functionality, performance, or user experience.
        - If unsure about a change's significance, omit it from the output.
        - Avoid adding any comments or notes; keep the output purely factual.

      These are the log messages including patches for the new release:

      %{log_diff}
    EOT
    options = ENV['OLLAMA_OPTIONS'].full? { |o| JSON.parse(o) } || {}
    options |= { "temperature" => 0, "top_p" => 1, "min_p" => 0.1 }
    ollama.generate(model:, system:, prompt:, options:, stream: false, think: false).response
  end

  def edit_temp_file(content)
    editor = ENV.fetch('EDITOR', `which vi`.chomp)
    unless File.exist?(editor)
      warn "Can't find EDITOR. => Returning."
      return
    end
    temp_file = Tempfile.new('changelog')
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

  def github_release_task
    namespace :github do
      unless github_api_token = ENV['GITHUB_API_TOKEN'].full?
        warn "GITHUB_API_TOKEN not set. => Skipping github release task."
        task :release
        return
      end
      desc "Create a new GitHub release for the current version with a changelog"
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

  dsl_accessor :push_task_dependencies, %i[ modified build master:push version:push gem:push github:release ]

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
    desc "Push master and version #{version} all git remotes: #{git_remotes * ' '}"
    task :push => push_task_dependencies
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
        output.write <<~EOT
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

  # The create_all_tasks method sets up and registers all the Rake tasks for
  # the gem project.
  #
  # @return [GemHadar] the instance of GemHadar
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
        s.rdoc_options << '--main' << readme
        s.extra_rdoc_files << readme
      end
      doc_files.full? { |df| s.extra_rdoc_files.concat Array(df) }
    end
  end

  # The warn method displays warning messages using orange colored output.
  #
  # @param msgs [Array<String>] the array of message strings to display
  def warn(*msgs)
    msgs.map! { |m| color(208) { m } }
    super(*msgs, uplevel: 1)
  end

  # The fail method formats and displays failure messages using red colored
  # output.
  #
  # @param args [Array] the array of arguments to be formatted and passed to super
  def fail(*args)
    args.map! do |a|
      a.respond_to?(:to_str) ? color(196) { a.to_str } : a
    end
    super(*args)
  end
  def fail(*args)
    args.map! do |a|
      a.respond_to?(:to_str) ? color(196) { a.to_str } : a
    end
    super(*args)
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
  def versions
    @versions ||= `git tag`.lines.grep(/^v?\d+\.\d+\.\d+$/).map(&:chomp).map {
      _1.sub(/\Av/, '')
    }.sort_by(&:version)
  end

  # The version_tag method prepends a 'v' prefix to the given version
  # string.
  #
  # @param version [String] the version string to modify
  # @return [String] the modified version string with a 'v' prefix
  def version_tag(version)
    version.dup.prepend ?v
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

  class << self
    # The start_simplecov method initializes SimpleCov and configures it to
    # ignore coverage data from the directory containing the caller. This can be
    # called from a test or spec helper.
    def start_simplecov
      defined? SimpleCov or return
      filter = "#{File.basename(File.dirname(caller.first))}/"
      SimpleCov.start do
        add_filter filter
      end
    end
  end
end

def GemHadar(&block)
  GemHadar.new(&block).create_all_tasks
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
