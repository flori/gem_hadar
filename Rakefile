# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'gem_hadar'
  module_type :class
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    "https://github.com/flori/#{name}"
  summary     'Library for the development of Ruby Gems'
  description 'This library contains some useful functionality to support the development of Ruby Gems'
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.AppleDouble', '.bundle', '.yardoc', 'tags'
  readme      'README.md'

  executables << 'gem_hadar'

  dependency  'tins', '~>1.0'
  dependency  'rake'
  dependency  'yard'

  licenses << 'MIT'
end
