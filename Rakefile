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
  ignore         '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.AppleDouble',
                 '.bundle', '.yardoc', 'doc', 'tags'
  package_ignore '.gitignore', 'VERSION'
  readme         'README.md'

  executables << 'gem_hadar'

  github_workflows(
    'static.yml' => { branches: '[ "master" ]' }
  )

  dependency 'tins',           '~> 1.0'
  dependency 'term-ansicolor', '~> 1.0'
  dependency 'ollama-ruby',    '~> 1.17'
  dependency 'infobar',        '~> 0.11'
  dependency 'mize'
  dependency 'rake'
  dependency 'yard'
  dependency 'openssl',        '>= 3.3.1'
  dependency 'net-http'
  dependency 'json',           '~> 2.0'
  dependency 'uri'
  dependency 'fileutils'
  dependency 'erb'
  development_dependency 'all_images'
  development_dependency 'rspec', '~> 3.13'
  development_dependency 'simplecov'

  licenses << 'MIT'
end
