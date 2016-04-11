# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'gem_hadar'
  module_type :class
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    "http://github.com/flori/#{name}"
  summary     'Library for the development of Ruby Gems'
  description 'This library contains some useful functionality to support the development of Ruby Gems'
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.AppleDouble', '.bundle', '.yardoc'
  readme      'README.md'

  dependency  'tins', '~>1.0'
  dependency  'rake'
  dependency  'yard'

  licenses << 'MIT'

  install_library do
    libdir = CONFIG["sitelibdir"]
    install("lib/#{name}.rb", libdir, :mode => 0644)
    mkdir_p subdir = File.join(libdir, name)
    for f in Dir["lib/#{name}/*.rb"]
      install(f, subdir)
    end
  end
end
