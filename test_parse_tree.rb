#!/usr/local/bin/ruby -w

require 'test/unit'
require 'parse_tree'
require 'something'

class TestParseTree < Test::Unit::TestCase

  @@missing = [nil]
  @@empty = [:defn, "empty", [:scope, [:args]]]
  @@simple = [:defn, "simple", [:scope, [:block, [:args, "arg1"], [:fcall, "print", [:array, [:lvar, "arg1"]]], [:fcall, "puts", [:array, [:call, [:lit, 4], "+", [:array, [:lit, 2]]]]]]]]
  @@conditional = [:defn, "conditional", [:scope, [:block, [:args, "arg1"], [:if, [:lvar, "arg1"], [:lit, 2], [:if, [:call, [:lvar, "arg1"], "nil?"], [:lit, 3], [:lit, 4]]]]]]
  @@iteration_body = [:scope, [:block, [:args], [:lasgn, "array", [:array, [:lit, 1], [:lit, 2], [:lit, 3]]], [:iter, [:call, [:lvar, "array"], "each"], [:dasgn_curr, "x"], [:fcall, "puts", [:array, [:dvar, "x"]]]]]]
  @@iteration1 = [:defn, "iteration1", @@iteration_body]
  @@iteration2 = [:defn, "iteration2", @@iteration_body]

  def setup
    @thing = ParseTree.new
  end

  def test_missing
    assert_equal(@@missing,
		 @thing.parse_tree(Something, :missing),
		 "Must return -3 for missing methods")
  end

  def test_empty
    assert_equal(@@empty,
		 @thing.parse_tree(Something, :empty),
		 "Must return an empty method body")
  end

  def test_simple
    assert_equal(@@simple,
		 @thing.parse_tree(Something, :simple),
		 "Must return a basic method body")
  end

  def test_conditional
    assert_equal(@@conditional,
		 @thing.parse_tree(Something, :conditional),
		 "Must return a conditional")
  end

  def test_iteration1
    assert_equal(@@iteration1,
		 @thing.parse_tree(Something, :iteration1),
		 "Must return an iteration")
  end

  def test_iteration2
    assert_equal(@@iteration2,
		 @thing.parse_tree(Something, :iteration2),
		 "Must return an iteration")
  end

  def ztest_class
    assert_equal([@@conditional, @@empty, @@iteration1, @@iteration2, @@simple],
		 @thing.parse_tree(Something),
		 "Must return a lot of shit")
  end

end
