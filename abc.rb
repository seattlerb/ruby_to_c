#!/usr/local/bin/ruby -w

# ABC metric
#
# Assignments, Branches, and Calls
#
# A simple way to measure the complexity of a function or method.

old_classes = []
ObjectSpace.each_object(Class) do |klass|
  old_classes << klass
end

require 'parse_tree'

ARGV.each do |name|
  require name
end

new_classes = []
ObjectSpace.each_object(Class) do |klass|
  new_classes << klass
end

score = {}

new_classes -= old_classes

new_classes.each do |klass|
  ParseTree.new.parse_tree(klass).each do |defn|
    a=b=c=0
    defn.shift
    name = defn.shift
    tokens = defn.flatten.find_all { |t| Symbol === t }
    tokens.each do |token|
      case token
      when :attrasgn, :attrset, :dasgn_curr, :iasgn, :lasgn, :masgn then
        a += 1
      when :and, :case, :else, :if, :iter, :or, :rescue, :until, :when, :while  then
        b += 1
      when :call, :fcall, :vcall, :yield then
        c += 1
      when :args, :argscat, :array, :begin, :block, :bool, :colon2, :const, :cvar, :defined, :defn, :dregx, :dstr, :dvar, :dxstr, :ensure, :false, :fbody, :gvar, :hash, :ivar, :lit, :long, :lvar, :match2, :match3, :nil, :not, :nth_ref, :return, :scope, :self, :splat, :str, :to_ary, :true, :unknown, :value, :void, :zarray, :zarray, :zclass then
        # ignore
      else
        puts "unhandled token #{token.inspect}"
      end
    end
    key = ["#{klass}.#{name}", a, b, c]
    val = a+b+c
    score[key] = val
  end
end

puts "Method = assignments + branches + calls = total"
puts
score.sort_by { |k,v| v }.reverse.each do |key,val|
  name, a, b, c = *key
  printf "%-50s = %2d + %2d + %2d = %3d\n", name, a, b, c, val
end
