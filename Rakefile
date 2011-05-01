require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see 
  # http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mpq"
  gem.homepage = "http://github.com/nolanw/mpq"
  gem.license = "WTFPL"
  gem.summary = %Q{Read files and metadata from MPQ archives}
  gem.description = %Q{Read files and metadata from MPQ archives}
  gem.email = "nolan@nolanw.ca"
  gem.authors = ["Nolan Waite"]
  # Include your dependencies below. Runtime dependencies are required when 
  # using your gem, and development dependencies are only needed for 
  # development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'bindata', '>= 1.3.1'
  gem.add_development_dependency 'rocco', '>= 0.6'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Prepare the mpq documentation"
task :docs do
  system("cd lib && rocco -o ../docs *.rb")
end

task :default => :test
