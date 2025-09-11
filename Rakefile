# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name           'gem_hadar'
  module_type    :class
  author         'Florian Frank'
  email          'flori@ping.de'
  homepage       "https://github.com/flori/#{name}"
  summary        'Library for the development of Ruby Gems'
  description    'This library contains some useful functionality to support the development of Ruby Gems'
  test_dir       'spec'
  ignore         '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.AppleDouble', '.bundle', '.yardoc', 'tags'
  package_ignore '.gitignore', 'VERSION'
  readme         'README.md'

  executables << 'gem_hadar'

  dependency 'tins',           '~> 1'
  dependency 'term-ansicolor', '~> 1.0'
  dependency 'ollama-ruby',    '~> 1.7'
  dependency 'mize'
  dependency 'rake'
  dependency 'yard'
  development_dependency 'rspec', '~> 3.13'

  licenses << 'MIT'
end
