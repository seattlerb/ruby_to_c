#!/usr/local/bin/ruby -ws

begin
  require 'rubygems'
  require_gem 'ParseTree'
rescue LoadError
  require 'parse_tree'
end

require 'ruby_to_c'

old_classes = []
ObjectSpace.each_object(Class) do |klass|
  old_classes << klass
end

ARGV.each do |name|
  require name
end

new_classes = []
ObjectSpace.each_object(Class) do |klass|
  new_classes << klass
end

new_classes -= old_classes
new_classes = [ eval($c) ] if defined? $c

rubytoc = RubyToC.translator

code = ParseTree.new.parse_tree(*new_classes).map do |klass|
  rubytoc.process(klass)
end # rescue nil

puts rubytoc.processors.last.preamble
puts code.join("\n\n")
