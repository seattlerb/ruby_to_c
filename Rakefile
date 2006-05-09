# -*- ruby -*-

require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rubygems'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs.push(*%w( test ../../ParseTree/dev/lib ../../ParseTree/dev/test ../../RubyInline/dev ))
  t.pattern = 'test/test_*.rb'
  t.verbose = true
end

VERSION = $1 if File.read('./lib/ruby_to_ansi_c.rb') =~ /VERSION = '([^']+)'/

spec = Gem::Specification.new do |s|
  s.name = 'RubyToC'
  s.version = VERSION.sub(/-beta-/, '.')
  s.summary = "Ruby (subset) to C translator."

  paragraphs = File.read("README.txt").split(/\n\n+/)
  s.description = paragraphs[2]
  puts s.description

  s.add_dependency('ParseTree')
  s.files = IO.readlines("Manifest.txt").reject { |o| o =~ /propaganda/ }.map {|f| f.chomp }

  s.require_path = 'lib'

  s.has_rdoc = true
  s.test_suite_file = "test/test_all.rb"

  s.author = "Ryan Davis"
  s.email = "ryand-ruby@zenspider.com"
  s.homepage = "http://rubyforge.org/projects/ruby2c/"
  s.rubyforge_project = "ruby2c"
end

Rake::GemPackageTask.new spec do |pkg|
  pkg.need_tar = true
end

