module GemHadar::Utils
  def xdg_config_filename(name)
    if xdg = ENV['XDG_CONFIG_HOME'].full?
      File.join(xdg, name)
    else
      File.join(ENV.fetch('HOME'), '.config', name)
    end
  end

  memoize method:
  def xdg_config(name, default)
    if File.exist?(xdg_config_filename(name))
      File.read(xdg_config_filename(name))
    else
      default
    end
  end
end
