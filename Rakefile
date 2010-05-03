begin
    require 'rubygems'
rescue LoadError
end

$:.unshift 'lib'
require 'methlab'
$:.shift

require 'rake/testtask'
require 'rdoc/task'
require 'rake/packagetask'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = "methlab"
  s.version = MethLab::VERSION
  s.author = "Erik Hollensbe"
  s.email = "erik@hollensbe.org"
  s.summary = "A method construction and validation toolkit."
  s.homepage = "http://github.com/erikh/methlab"

  s.files = Dir["lib/**/*"] + Dir["test/**/*"] + Dir["Rakefile"] + Dir["README"]

  s.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |s|
end

Rake::PackageTask.new(spec.name, spec.version) do |p|
    p.need_tar_gz = true
    p.need_zip = true
    p.package_files.include("./bin/**/*")
    p.package_files.include("./Rakefile")
    p.package_files.include("./lib/**/*.rb")
    p.package_files.include("./test/**/*")
    p.package_files.include("README")
end

Rake::TestTask.new do |t|
    t.libs << 'lib'
    t.test_files = FileList['test/test*.rb']
    t.verbose = true 
end

RDoc::Task.new do |rd|
    rd.rdoc_dir = "rdoc"
    rd.main = "README"
    rd.title = "MethLab: A method toolkit for Ruby"
    rd.rdoc_files.include("./lib/**/*.rb")
    rd.rdoc_files.include("README")
    rd.options = %w(-a)
end

task :fixperms do
    chmod(0644, Dir['**/*'])  
end

task :default => [:clean, :test, :build]
desc "Build Packages"
task :build => [:gem, :repackage]
task :distclean => [:clobber_package, :clobber_rdoc]
desc "Clean the source tree"
task :clean => [:distclean]

task :to_blog => [:clobber_rdoc, :rdoc] do
    sh "rm -r $git/blog/content/docs/methlab && mv rdoc $git/blog/content/docs/methlab"
end
