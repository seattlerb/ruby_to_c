#!/usr/local/bin/ruby -w

require 'test/unit'
require 'parse_tree'
require 'something'

class TestParseTree < Test::Unit::TestCase

  # TODO: need a test of interpolated strings

  @@missing = [nil]
  @@empty = [:defn, "empty",
    [:scope,
      [:args]]]
  @@stupid = [:defn, "stupid",
    [:scope,
      [:block,
        [:args],
        [:return, [:nil]]]]]
  @@simple = [:defn, "simple",
    [:scope,
      [:block,
        [:args, "arg1"],
        [:fcall, "print",
          [:array, [:lvar, "arg1"]]],
        [:fcall, "puts",
          [:array,
            [:call,
              [:lit, 4],
              "+",
              [:array, [:lit, 2]]]]]]]]
  @@global = [:defn, "global",
    [:scope,
      [:block,
        [:args],
        [:call,
          [:gvar, "$stderr"],
          "puts",
          [:array, [:str, "blah"]]]]]]
  @@lasgn_call = [:defn, "lasgn_call",
    [:scope,
      [:block,
        [:args],
        [:lasgn, "c",
          [:call,
            [:lit, 2],
            "+",
            [:array, [:lit, 3]]]]]]]
  @@conditional1 = [:defn, "conditional1",
    [:scope,
      [:block,
        [:args, "arg1"],
        [:if,
          [:call,
            [:lvar, "arg1"],
            "==",
            [:array, [:lit, 0]]],
          [:return,
            [:lit, 1]], nil]]]]
  @@conditional2 = [:defn, "conditional2",
    [:scope,
      [:block,
        [:args, "arg1"],
        [:if,
          [:call,
            [:lvar, "arg1"],
            "==",
            [:array, [:lit, 0]]], nil,
          [:return,
            [:lit, 2]]]]]]
  @@conditional3 = [:defn, "conditional3",
    [:scope,
      [:block,
        [:args, "arg1"],
        [:if,
          [:call,
            [:lvar, "arg1"],
            "==",
            [:array, [:lit, 0]]],
          [:return,
            [:lit, 3]],
          [:return,
            [:lit, 4]]]]]]
  @@conditional4 = [:defn, "conditional4",
    [:scope,
      [:block,
        [:args, "arg1"],
        [:if,
          [:call,
            [:lvar, "arg1"],
            "==",
            [:array, [:lit, 0]]],
          [:return, [:lit, 2]],
          [:if,
            [:call,
              [:lvar, "arg1"],
              "<",
              [:array, [:lit, 0]]],
            [:return, [:lit, 3]],
            [:return, [:lit, 4]]]]]]]
  @@iteration_body = [:scope,
    [:block,
      [:args],
      [:lasgn, "array",
        [:array, [:lit, 1], [:lit, 2], [:lit, 3]]],
      [:iter,
        [:call,
          [:lvar, "array"], "each"],
        [:dasgn_curr, "x"],
        [:fcall, "puts", [:array, [:dvar, "x"]]]]]]
  @@iteration1 = [:defn, "iteration1", @@iteration_body]
  @@iteration2 = [:defn, "iteration2", @@iteration_body]
  @@iteration3 = [:defn, "iteration3",
    [:scope,
      [:block,
        [:args],
        [:lasgn, "array1",
          [:array, [:lit, 1], [:lit, 2], [:lit, 3]]],
        [:lasgn, "array2",
          [:array, [:lit, 4], [:lit, 5], [:lit, 6], [:lit, 7]]],
        [:iter,
          [:call,
            [:lvar, "array1"], "each"],
          [:dasgn_curr, "x"],
          [:iter,
            [:call,
              [:lvar, "array2"], "each"],
            [:dasgn_curr, "y"],
            [:block,
              [:fcall, "puts",
                [:array, [:dvar, "x"]]],
              [:fcall, "puts",
                [:array, [:dvar, "y"]]]]]]]]]
  @@multi_args = [:defn, "multi_args",
    [:scope,
      [:block,
        [:args, "arg1", "arg2"],
        [:fcall, "puts",
          [:array, [:call,
              [:lvar, "arg1"],
              "*",
              [:array, [:lvar, "arg2"]]]]],
        [:return,
          [:str, "foo"]]]]]
  @@bools = [:defn, "bools",
    [:scope,
      [:block,
        [:args, "arg1"],
        [:if,
          [:call,
            [:lvar, "arg1"], "nil?"],
          [:return,
            [:false]],
          [:return,
            [:true]]]]]]

  @@__all = []

  def setup
    @thing = ParseTree.new
  end

  Something.instance_methods(false).sort.each do |meth|
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}; assert_equal @@#{meth}, @thing.parse_tree(Something, :#{meth}); end"
    else
      eval "def test_#{meth}; flunk \"You haven't added @@#{meth} yet\"; end"
    end
  end

  def test_missing
    assert_equal(@@missing,
		 @thing.parse_tree(Something, :missing),
		 "Must return -3 for missing methods")
  end

  def ztest_class
    assert_equal(@@__all,
		 @thing.parse_tree(Something),
		 "Must return a lot of shit")
  end

end

