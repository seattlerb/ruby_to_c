# -*- ruby -*-

require 'rubygems'
require 'ruby_to_c'

spec = Gem::Specification.new do |s|

  s.name = 'RubyToC'
  s.version = RubyToC::VERSION.sub(/-beta-/, '.')
  s.summary = "Ruby (subset) to C translator."

  paragraphs = File.read("README.txt").split(/\n\n+/)
  s.description = paragraphs[2]
  puts s.description

  s.add_dependency('ParseTree')
  s.files = IO.readlines("Manifest.txt").reject { |o| o =~ /propaganda/ }.map {|f| f.chomp }

  s.require_path = '.' 
  s.autorequire = 'ruby_to_c'

  s.has_rdoc = true
  s.test_suite_file = "test_all.rb"

  s.author = "Ryan Davis"
  s.email = "ryand-ruby@zenspider.com"
  s.homepage = "http://rubyforge.org/projects/ruby2c/"
  s.rubyforge_project = "ruby2c"
end

if $0 == __FILE__
  Gem.manage_gems
  Gem::Builder.new(spec).build
end
