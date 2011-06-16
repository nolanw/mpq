# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mpq}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nolan Waite"]
  s.date = %q{2011-06-16}
  s.description = %q{Read files and metadata from MPQ archives}
  s.email = %q{nolan@nolanw.ca}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "lib/jsonish.rb",
    "lib/mpq.rb",
    "lib/replay_file.rb",
    "mpq.gemspec",
    "test/helper.rb",
    "test/some.SC2Replay",
    "test/test_jsonish.rb",
    "test/test_mpq.rb",
    "test/test_replay_file.rb"
  ]
  s.homepage = %q{http://github.com/nolanw/mpq}
  s.licenses = ["WTFPL"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{Read files and metadata from MPQ archives}
  s.test_files = [
    "test/helper.rb",
    "test/test_jsonish.rb",
    "test/test_mpq.rb",
    "test/test_replay_file.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bindata>, ["~> 1.3.1"])
      s.add_runtime_dependency(%q<bzip2-ruby>, ["~> 0.2.7"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rocco>, ["~> 0.6"])
      s.add_runtime_dependency(%q<bindata>, [">= 1.3.1"])
      s.add_development_dependency(%q<rocco>, [">= 0.6"])
    else
      s.add_dependency(%q<bindata>, ["~> 1.3.1"])
      s.add_dependency(%q<bzip2-ruby>, ["~> 0.2.7"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rocco>, ["~> 0.6"])
      s.add_dependency(%q<bindata>, [">= 1.3.1"])
      s.add_dependency(%q<rocco>, [">= 0.6"])
    end
  else
    s.add_dependency(%q<bindata>, ["~> 1.3.1"])
    s.add_dependency(%q<bzip2-ruby>, ["~> 0.2.7"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rocco>, ["~> 0.6"])
    s.add_dependency(%q<bindata>, [">= 1.3.1"])
    s.add_dependency(%q<rocco>, [">= 0.6"])
  end
end
