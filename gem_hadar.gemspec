# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "gem_hadar"
  s.version = "0.1.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = "2012-03-09"
  s.description = "This library contains some useful functionality to support the development of Ruby Gems"
  s.email = "flori@ping.de"
  s.extra_rdoc_files = ["README.rdoc", "lib/gem_hadar/version.rb", "lib/gem_hadar.rb"]
  s.files = [".gitignore", "Gemfile", "LICENSE", "README.rdoc", "Rakefile", "VERSION", "gem_hadar.gemspec", "lib/gem_hadar.rb", "lib/gem_hadar/version.rb"]
  s.homepage = "http://github.com/flori/gem_hadar"
  s.rdoc_options = ["--title", "GemHadar - Library for the development of Ruby Gems", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.17"
  s.summary = "Library for the development of Ruby Gems"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 0.1.6"])
      s.add_runtime_dependency(%q<tins>, [">= 0.3.3"])
      s.add_runtime_dependency(%q<dslkit>, ["~> 0.2"])
      s.add_runtime_dependency(%q<sdoc>, ["~> 0.2.20"])
      s.add_runtime_dependency(%q<rake>, ["~> 0.9.2"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 0.1.6"])
      s.add_dependency(%q<tins>, [">= 0.3.3"])
      s.add_dependency(%q<dslkit>, ["~> 0.2"])
      s.add_dependency(%q<sdoc>, ["~> 0.2.20"])
      s.add_dependency(%q<rake>, ["~> 0.9.2"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 0.1.6"])
    s.add_dependency(%q<tins>, [">= 0.3.3"])
    s.add_dependency(%q<dslkit>, ["~> 0.2"])
    s.add_dependency(%q<sdoc>, ["~> 0.2.20"])
    s.add_dependency(%q<rake>, ["~> 0.9.2"])
  end
end
