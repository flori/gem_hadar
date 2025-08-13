# A class that handles the initialization and setup of a new gem project
# structure.
#
# This class is responsible for creating the basic directory layout and
# configuration files needed for a Ruby gem project. It ensures that essential
# components like the lib directory, VERSION file, and Rakefile are in place,
# providing a solid foundation for gem development.
#
# @example Setting up a new gem project
#   setup = GemHadar::Setup.new
#   setup.perform
class GemHadar::Setup
  include FileUtils

  # The perform method sets up the basic project structure by creating the lib
  # directory, initializing a VERSION file with '0.0.0' if it doesn't exist,
  # and creating a default Rakefile with basic GemHadar configuration if one
  # doesn't already exist.
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
