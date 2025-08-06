module GemHadar::Utils
  # The xdg_config_filename method constructs the full path to a configuration
  # file based on the XDG Base Directory specification.
  #
  # It first checks if the XDG_CONFIG_HOME environment variable is set and not
  # empty. If it is set, the method joins this directory with the provided
  # filename to form the complete path. If XDG_CONFIG_HOME is not set, it
  # defaults to using the HOME environment variable to construct the path
  # within the standard .config directory.
  #
  # @param name [ String ] the name of the configuration file
  #
  # @return [ String ] the full path to the configuration file
  def xdg_config_filename(name)
    if xdg = ENV['XDG_CONFIG_HOME'].full?
      File.join(xdg, name)
    else
      File.join(ENV.fetch('HOME'), '.config', name)
    end
  end

  # The xdg_config method retrieves configuration data from a file following
  # the XDG Base Directory specification.
  #
  # It checks for the existence of a configuration file using the
  # xdg_config_filename method and returns its contents if found. If the file
  # does not exist, it returns the provided default value instead.
  #
  # @param name [ String ] the name of the configuration file to retrieve
  # @param default [ Object ] the default value to return if the configuration file is not found
  #
  # @return [ String ] the content of the configuration file or the default value
  memoize method:
  def xdg_config(name, default)
    if File.exist?(xdg_config_filename(name))
      File.read(xdg_config_filename(name))
    else
      default
    end
  end
end
