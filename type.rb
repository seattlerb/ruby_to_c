#!/usr/local/bin/ruby -w

require 'pp'
require 'type_checker'

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
type_checker = TypeChecker.new

new_classes.each do |klass|
  sexp = parser.parse_tree klass
  sexp.each do |exp|
    exp = type_checker.process(rewriter.process(exp))
    pp exp.to_a
  end
end
