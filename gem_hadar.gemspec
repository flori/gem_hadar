# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gem_hadar}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = %q{2011-07-15}
  s.description = %q{This library contains some useful functionality to support the development of Ruby Gems}
  s.email = %q{flori@ping.de}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = [".gitignore", "Gemfile", "LICENSE", "README.rdoc", "Rakefile", "VERSION", "gem_hadar.gemspec", "lib/gem_hadar.rb", "lib/gem_hadar/version.rb"]
  s.homepage = %q{http://github.com/flori/gem_hadar}
  s.rdoc_options = ["--title", "GemHadar - Library for the development of Ruby Gems", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Library for the development of Ruby Gems}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 0.0.0"])
      s.add_runtime_dependency(%q<spruz>, ["~> 0.2.10"])
      s.add_runtime_dependency(%q<dslkit>, ["~> 0.2.6"])
      s.add_runtime_dependency(%q<sdoc>, ["~> 0.2.20"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 0.0.0"])
      s.add_dependency(%q<spruz>, ["~> 0.2.10"])
      s.add_dependency(%q<dslkit>, ["~> 0.2.6"])
      s.add_dependency(%q<sdoc>, ["~> 0.2.20"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 0.0.0"])
    s.add_dependency(%q<spruz>, ["~> 0.2.10"])
    s.add_dependency(%q<dslkit>, ["~> 0.2.6"])
    s.add_dependency(%q<sdoc>, ["~> 0.2.20"])
  end
end
