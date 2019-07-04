# -*- encoding: utf-8 -*-
# stub: gem_hadar 1.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gem_hadar".freeze
  s.version = "1.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "2019-07-04"
  s.description = "This library contains some useful functionality to support the development of Ruby Gems".freeze
  s.email = "flori@ping.de".freeze
  s.extra_rdoc_files = ["README.md".freeze, "lib/gem_hadar.rb".freeze, "lib/gem_hadar/version.rb".freeze]
  s.files = [".gitignore".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "gem_hadar.gemspec".freeze, "lib/gem_hadar.rb".freeze, "lib/gem_hadar/version.rb".freeze]
  s.homepage = "http://github.com/flori/gem_hadar".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "GemHadar - Library for the development of Ruby Gems".freeze, "--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Library for the development of Ruby Gems".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 1.10.0"])
      s.add_runtime_dependency(%q<tins>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<rake>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<yard>.freeze, [">= 0"])
    else
      s.add_dependency(%q<gem_hadar>.freeze, ["~> 1.10.0"])
      s.add_dependency(%q<tins>.freeze, ["~> 1.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<yard>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<gem_hadar>.freeze, ["~> 1.10.0"])
    s.add_dependency(%q<tins>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
  end
end
