# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gem_hadar}
  s.version = "0.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Florian Frank}]
  s.date = %q{2011-08-05}
  s.description = %q{This library contains some useful functionality to support the development of Ruby Gems}
  s.email = %q{flori@ping.de}
  s.extra_rdoc_files = [%q{README.rdoc}, %q{lib/gem_hadar.rb}, %q{lib/gem_hadar/version.rb}]
  s.files = [%q{.gitignore}, %q{Gemfile}, %q{LICENSE}, %q{README.rdoc}, %q{Rakefile}, %q{VERSION}, %q{gem_hadar.gemspec}, %q{lib/gem_hadar.rb}, %q{lib/gem_hadar/version.rb}]
  s.homepage = %q{http://github.com/flori/gem_hadar}
  s.rdoc_options = [%q{--title}, %q{GemHadar - Library for the development of Ruby Gems}, %q{--main}, %q{README.rdoc}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Library for the development of Ruby Gems}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 0.0.9"])
      s.add_runtime_dependency(%q<spruz>, ["~> 0.2"])
      s.add_runtime_dependency(%q<dslkit>, ["~> 0.2"])
      s.add_runtime_dependency(%q<sdoc>, ["~> 0.2.20"])
      s.add_runtime_dependency(%q<rake>, ["~> 0.9.2"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 0.0.9"])
      s.add_dependency(%q<spruz>, ["~> 0.2"])
      s.add_dependency(%q<dslkit>, ["~> 0.2"])
      s.add_dependency(%q<sdoc>, ["~> 0.2.20"])
      s.add_dependency(%q<rake>, ["~> 0.9.2"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 0.0.9"])
    s.add_dependency(%q<spruz>, ["~> 0.2"])
    s.add_dependency(%q<dslkit>, ["~> 0.2"])
    s.add_dependency(%q<sdoc>, ["~> 0.2.20"])
    s.add_dependency(%q<rake>, ["~> 0.9.2"])
  end
end
