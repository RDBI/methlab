require 'rubygems'
require 'rake'

version = (File.exist?('VERSION') ? File.read('VERSION') : "").chomp

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "methlab"
    gem.email = "erik@hollensbe.org"
    gem.summary = "A method construction and validation toolkit."
    gem.homepage = "http://github.com/RDBI/methlab"
    gem.authors = ["Erik Hollensbe"]

    gem.add_development_dependency 'rdoc'
    gem.add_development_dependency 'test-unit'

    ## for now, install hanna from here: http://github.com/raggi/hanna
    gem.add_development_dependency 'hanna'

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

begin
  gem 'test-unit'
  require 'rake/testtask'
  Rake::TestTask.new(:test) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :test do
    abort "test-unit gem is not available. In order to run test-unit, you must: sudo gem install test-unit"
  end
end


begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

begin
  require 'roodi'
  require 'roodi_task'
  RoodiTask.new do |t|
    t.verbose = false
  end
rescue LoadError
  task :roodi do
    abort "Roodi is not available. In order to run roodi, you must: sudo gem install roodi"
  end
end

task :default => :test

begin
  require 'hanna'
  require 'rdoc/task'
  RDoc::Task.new do |rdoc|
    version = File.exist?('VERSION') ? File.read('VERSION') : ""

    rdoc.options.push '-f', 'hanna'
    rdoc.main = 'README.rdoc'
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "RDBI #{version} Documentation"
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue LoadError => e
  rdoc_missing = lambda do
    abort "What, were you born in a barn? Install rdoc and hanna at http://github.com/erikh/hanna ."
  end
  task :rdoc, &rdoc_missing
  task :clobber_rdoc, &rdoc_missing
end

task :install => [:test, :build]

task :docview => [:rerdoc] do
  sh "open rdoc/index.html"
end

# vim: syntax=ruby ts=2 et sw=2 sts=2
