#!/usr/local/bin/ruby -w

require 'pp'
require 'rewriter'

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

parser = ParseTree.new
rewriter = Rewriter.new

new_classes.each do |klass|
  sexp = parser.parse_tree klass
  sexp.each do |exp|
    exp = rewriter.process(exp)
    pp exp
  end
end

