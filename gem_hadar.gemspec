# -*- encoding: utf-8 -*-
# stub: gem_hadar 1.21.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gem_hadar".freeze
  s.version = "1.21.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "1980-01-02"
  s.description = "This library contains some useful functionality to support the development of Ruby Gems".freeze
  s.email = "flori@ping.de".freeze
  s.executables = ["gem_hadar".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "lib/gem_hadar.rb".freeze, "lib/gem_hadar/github.rb".freeze, "lib/gem_hadar/setup.rb".freeze, "lib/gem_hadar/template_compiler.rb".freeze, "lib/gem_hadar/version.rb".freeze]
  s.files = [".gitignore".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "bin/gem_hadar".freeze, "gem_hadar.gemspec".freeze, "lib/gem_hadar.rb".freeze, "lib/gem_hadar/github.rb".freeze, "lib/gem_hadar/setup.rb".freeze, "lib/gem_hadar/template_compiler.rb".freeze, "lib/gem_hadar/version.rb".freeze]
  s.homepage = "https://github.com/flori/gem_hadar".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "GemHadar - Library for the development of Ruby Gems".freeze, "--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Library for the development of Ruby Gems".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 1.21".freeze])
  s.add_runtime_dependency(%q<tins>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<term-ansicolor>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<ollama-ruby>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<yard>.freeze, [">= 0".freeze])
end
