#!/usr/local/bin/ruby -w

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
      when :args, :argscat, :array, :begin, :block, :bool, :const, :defined, :defn, :dstr, :dvar, :ensure, :false, :fbody, :gvar, :hash, :ivar, :lit, :long, :lvar, :match3, :nil, :not, :nth_ref, :return, :scope, :self, :str, :to_ary, :true, :unknown, :value, :void, :zarray, :zarray, :zclass then
        # ignore

      else
        puts "unhandled token #{token.inspect}"
      end
    end
    puts "#{klass}.#{name}:#{a}:#{b}:#{c}=#{a+b+c}"
  end
end
