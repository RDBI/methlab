# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{methlab}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Erik Hollensbe"]
  s.date = %q{2010-10-03}
  s.default_executable = %q{rake}
  s.email = %q{erik@hollensbe.org}
  s.executables = ["rake"]
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "README",
     "Rakefile",
     "VERSION",
     "lib/methlab.rb",
     "lib/methlab/yard.rb",
     "methlab.gemspec",
     "test/test_checks.rb",
     "test/test_defaults.rb",
     "test/test_inline.rb",
     "test/test_integrate.rb"
  ]
  s.homepage = %q{http://github.com/RDBI/methlab}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A method construction and validation toolkit.}
  s.test_files = [
    "test/test_checks.rb",
     "test/test_defaults.rb",
     "test/test_inline.rb",
     "test/test_integrate.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
      s.add_development_dependency(%q<hanna>, [">= 0"])
    else
      s.add_dependency(%q<rdoc>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
      s.add_dependency(%q<hanna>, [">= 0"])
    end
  else
    s.add_dependency(%q<rdoc>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
    s.add_dependency(%q<hanna>, [">= 0"])
  end
end
