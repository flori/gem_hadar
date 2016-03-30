# -*- encoding: utf-8 -*-
# stub: gem_hadar 1.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gem_hadar"
  s.version = "1.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Florian Frank"]
  s.date = "2016-03-30"
  s.description = "This library contains some useful functionality to support the development of Ruby Gems"
  s.email = "flori@ping.de"
  s.extra_rdoc_files = ["README.md", "lib/gem_hadar.rb", "lib/gem_hadar/version.rb"]
  s.files = [".gitignore", "Gemfile", "LICENSE", "README.md", "Rakefile", "VERSION", "gem_hadar.gemspec", "lib/gem_hadar.rb", "lib/gem_hadar/version.rb"]
  s.homepage = "http://github.com/flori/gem_hadar"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--title", "GemHadar - Library for the development of Ruby Gems", "--main", "README.md"]
  s.rubygems_version = "2.5.1"
  s.summary = "Library for the development of Ruby Gems"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 1.5.0"])
      s.add_runtime_dependency(%q<tins>, ["~> 1.0"])
      s.add_runtime_dependency(%q<rake>, ["~> 10.0"])
      s.add_runtime_dependency(%q<yard>, [">= 0"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 1.5.0"])
      s.add_dependency(%q<tins>, ["~> 1.0"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<yard>, [">= 0"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 1.5.0"])
    s.add_dependency(%q<tins>, ["~> 1.0"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<yard>, [">= 0"])
  end
end
