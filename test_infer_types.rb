#!/usr/local/bin/ruby -w

require 'test/unit'

require 'parse_tree'
require 'infer_types'
require 'something'

class TestInferTypes < Test::Unit::TestCase

  # TODO: methods with no return stmt should have return type of :none
  @@empty = [:defn, "empty", [:scope, [:args]], [:unknown]]
  @@stupid = [:defn, "stupid", [:scope, [:block, [:args], [:return, [:nil]]]], [:nil]]
  @@simple = [:defn, "simple", [:scope, [:block, [:args, ["arg1", [:unknown]]], [:fcall, "print", [:array, [:lvar, "arg1"]]], [:fcall, "puts", [:array, [:call, [:lit, 4], "+", [:array, [:lit, 2]]]]]]], [:unknown]]
  @@global = [:defn, "global", [:scope, [:block, [:args], [:call, [:gvar, "$stderr", :file], "puts", [:array, [:str, "blah"]]]]], [:unknown]]
  @@lasgn_call = [:defn, "lasgn_call", [:scope, [:block, [:args], [:lasgn, "c", [:call, [:lit, 2], "+", [:array, [:lit, 3]]], [:long]]]], [:unknown]]
  @@conditional1 = [:defn, "conditional1", [:scope, [:block, [:args, ["arg1", [:long]]], [:if, [:call, [:lvar, "arg1"], "==", [:array, [:lit, 0]]], [:return, [:lit, 1]], nil]]], [:long]]
  @@conditional2 = [:defn, "conditional2", [:scope, [:block, [:args, ["arg1", [:long]]], [:if, [:call, [:lvar, "arg1"], "==", [:array, [:lit, 0]]], nil, [:return, [:lit, 2]]]]], [:long]]
  @@conditional3 = [:defn, "conditional3", [:scope, [:block, [:args, ["arg1", [:long]]], [:if, [:call, [:lvar, "arg1"], "==", [:array, [:lit, 0]]], [:return, [:lit, 3]], [:return, [:lit, 4]]]]], [:long]]
  @@conditional4 = [:defn, "conditional4", [:scope, [:block, [:args, ["arg1", [:long]]], [:if, [:call, [:lvar, "arg1"], "==", [:array, [:lit, 0]]], [:return, [:lit, 2]], [:if, [:call, [:lvar, "arg1"], "<", [:array, [:lit, 0]]], [:return, [:lit, 3]], [:return, [:lit, 4]]]]]], [:long]]
  @@iteration_body = [:scope, [:block, [:args], [:lasgn, "array", [:array, [:lit, 1], [:lit, 2], [:lit, 3]], [:list, [:long]]], [:iter, [:call, [:lvar, "array"], "each"], [:dasgn_curr, ["x", [:long]]], [:fcall, "puts", [:array, [:dvar, "x"]]]]]]
  @@iteration1 = [:defn, "iteration1", @@iteration_body, [:unknown]]
  @@iteration2 = [:defn, "iteration2", @@iteration_body, [:unknown]]
  @@iteration3 = [:defn, "iteration3", [:scope, [:block, [:args], [:lasgn, "array1", [:array, [:lit, 1], [:lit, 2], [:lit, 3]], [:list, [:long]]], [:lasgn, "array2", [:array, [:lit, 4], [:lit, 5], [:lit, 6], [:lit, 7]], [:list, [:long]]], [:iter, [:call, [:lvar, "array1"], "each"], [:dasgn_curr, ["x", [:long]]], [:iter, [:call, [:lvar, "array2"], "each"], [:dasgn_curr, ["y", [:long]]], [:block, [:fcall, "puts", [:array, [:dvar, "x"]]], [:fcall, "puts", [:array, [:dvar, "y"]]]]]]]], [:unknown]]
  @@multi_args = [:defn, "multi_args", [:scope, [:block, [:args, ["arg1", [:unknown]], ["arg2", [:unknown]]], [:fcall, "puts", [:array, [:call, [:lvar, "arg1"], "*", [:array, [:lvar, "arg2"]]]]], [:return, [:str, "foo"]]]], [:str]]
  @@bools = [:defn, "bools", [:scope, [:block, [:args, ["arg1", [:unknown]]], [:if, [:call, [:lvar, "arg1"], "nil?"], [:return, [:false]], [:return, [:true]]]]], [:bool]]

  @@augmenter = InferTypes.new

  Something.instance_methods(false).each do |meth|
    if class_variables.include?("@@#{meth}") then
      eval "def test_#{meth}; assert_equal @@#{meth}, @@augmenter.augment(Something, :#{meth}); end"
    else
      eval "def test_#{meth}; flunk \"You haven't added @@#{meth} yet\"; end"
    end
  end

end

