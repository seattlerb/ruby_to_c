# -*- ruby -*-

require 'rake'
require 'rake/contrib/sshpublisher'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rubygems'
require 'rbconfig'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs.push(*%w( test ../../ParseTree/dev/lib ../../ParseTree/dev/test ../../RubyInline/dev ))
  t.pattern = 'test/test_*.rb'
  t.verbose = true
end

R2C_VERSION = $1 if File.read('./lib/ruby_to_ansi_c.rb') =~ /VERSION = '([^']+)'/

spec = Gem::Specification.new do |s|
  s.name = 'RubyToC'
  s.version = R2C_VERSION.sub(/-beta-/, '.')
  s.authors = ['Ryan Davis', 'Eric Hodel']
  s.email = 'ryand-ruby@zenspider.com'
  s.summary = "Ruby (subset) to C translator."

  paragraphs = File.read("README.txt").split(/\n\n+/)
  s.description = paragraphs[2]

  s.add_dependency('ParseTree')
  s.files = IO.readlines("Manifest.txt").map {|f| f.chomp }

  s.executables = s.files.grep(/^bin\//).map { |f| File.basename f }

  s.require_path = 'lib'

  s.has_rdoc = true
  s.test_suite_file = "test/test_all.rb"

  s.author = "Ryan Davis"
  s.email = "ryand-ruby@zenspider.com"
  s.homepage = "http://rubyforge.org/projects/ruby2c/"
  s.rubyforge_project = "ruby2c"

  if $DEBUG then
    puts "#{s.name} #{s.version}"
    puts
    puts s.executables.sort.inspect
    puts
    puts "** summary:"
    puts s.summary
    puts
    puts "** description:"
    puts s.description
  end
end

Rake::GemPackageTask.new spec do |pkg|
  pkg.need_tar = true
end

task :sort do
  sh 'for f in lib/*.rb; do grep "^ *def " $f | grep -v "def self" > x; sort x > y; echo; echo $f; echo; diff x y; done; true'
  sh 'for f in test/test_*.rb; do grep "def.test_" $f > x; sort x > y; echo; echo $f; echo; diff x y; done; true'
  sh 'rm x y'
end

Rake::RDocTask.new :rdoc do |rd|
  rd.main = "RubyToAnsiC"
  rd.rdoc_dir = 'doc'
  rd.options << '-d' if RUBY_PLATFORM !~ /win32/ && `which dot` =~ /\/dot/
  rd.options << '-t "ruby2c RDoc"'
  rd.rdoc_files.include("lib/*.rb")
end

desc 'Upload RDoc to RubyForge'
task :upload => :rdoc do
  user = ENV['USER']
  user = "zenspider" if user == "ryan"
  user = "#{user}@rubyforge.org"
  project = '/var/www/gforge-projects/ruby2c'
  local_dir = 'doc'
  pub = Rake::SshDirPublisher.new user, project, local_dir
  pub.upload
end

desc 'Clean up'
task :clean => [ :clobber_rdoc, :clobber_package ] do
  rm_f(Dir["**/*~"] +
       Dir["**/*.diff"] +
       Dir["demo/*.rb"].map { |f|
         fb=File.basename(f, ".rb"); [fb, fb + ".c"]
       }.flatten)
  rm_rf File.expand_path("~/.ruby_inline")
end

$prefix = ENV['PREFIX'] || Config::CONFIG['prefix']
$bin  = File.join($prefix, 'bin')
$lib  = Config::CONFIG['sitelibdir']
$bins = spec.executables
$libs = spec.files.grep(/^lib\//).map { |f| f.sub(/^lib\//, '') }.sort

task :install do
  $bins.each do |f|
    install File.join("bin", f), $bin, :mode => 0555
  end

  $libs.each do |f|
    dir = File.join($lib, File.dirname(f))
    mkdir_p dir unless test ?d, dir
    install File.join("lib", f), dir, :mode => 0444
  end
end

task :uninstall do
  $bins.each do |f|
    rm_f File.join($bin, f)
  end

  $libs.each do |f|
    rm_f File.join($lib, f)
  end
end

task :help do
  Rake.application.options.show_task_pattern = //
  Rake.application.display_tasks_and_comments
end
