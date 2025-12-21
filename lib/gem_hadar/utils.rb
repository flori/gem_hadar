require 'pathname'

# A module that provides utility methods for GemHadar
#
# This module contains helper methods for common operations within the GemHadar
# framework, including XDG configuration directory handling, user input
# prompts, and memoization capabilities. It serves as a collection of reusable
# utilities that support various aspects of gem automation and configuration
# management.
module GemHadar::Utils
  # The xdg_config_home method determines the XDG configuration directory path.
  #
  # This method returns the path to the XDG configuration directory, which is used
  # to store user-specific configuration files for applications. It first checks
  # the XDG_CONFIG_HOME environment variable and returns its value if set.
  # If the environment variable is not set, it falls back to the default
  # configuration directory within the user's home directory, typically
  # ~/.config.
  #
  # @return [ Pathname ] the Pathname object representing the XDG configuration
  #   directory path
  def xdg_config_home
    ENV['XDG_CONFIG_HOME'].full? { Pathname.new(_1) } ||
      Pathname.new(ENV.fetch('HOME')) + '.config'
  end

  # The xdg_config_dir method constructs the path to the XDG configuration
  # directory for a specific application.
  #
  # This method takes an application name and returns the full path to the
  # configuration directory for that application within the XDG configuration
  # home directory.
  #
  # @param app [ String ] the name of the application to get the configuration
  #   directory for
  #
  # @return [ Pathname ] the Pathname object representing the application's
  #   configuration directory path
  def xdg_config_dir(app)
    xdg_config_home + app
  end

  # The xdg_config_filename method constructs the full path to a configuration
  # file within the XDG configuration directory for a specific application.
  #
  # This method takes an application name and a filename, then combines them
  # with the XDG configuration directory path to create the full path to a
  # configuration file.
  #
  # @param app [ String ] the name of the application to get the configuration
  #   directory for
  # @param name [ String ] the name of the configuration file
  #
  # @return [ Pathname ] the Pathname object representing the full path to the
  #   configuration file
  def xdg_config_filename(app, name)
    xdg_config_dir(app) + name
  end

  # The xdg_config method retrieves configuration content from XDG
  # configuration directories
  #
  # This method checks for the existence of a configuration file within the XDG
  # configuration directory structure for the specified application. If the
  # file exists, it reads and returns the file's content. If the file does not
  # exist, it returns the provided default value instead.
  #
  # @param app [ String ] the name of the application to get the configuration
  #   directory for
  # @param name [ String ] the name of the configuration file
  # @param default [ String ] the default value to return if the configuration
  #   file does not exist
  #
  # @return [ String ] the content of the configuration file or the default
  #   value if the file does not exist
  def xdg_config(app, name, default)
    if xdg_config_filename(app, name).exist?
      File.read(xdg_config_filename(app, name))
    else
      default
    end
  end
  memoize method: :xdg_config

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
end
