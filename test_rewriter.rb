#!/usr/local/bin/ruby -w

require 'test/unit'
require 'rewriter'

class TestRewriter < Test::Unit::TestCase

  def setup
    @rewrite = Rewriter.new
  end

  def test_case
    input = [:case,
      [:lvar, "var"],
      [:when, [:array, [:lit, 1]], [:str, "1"]],
      [:when, [:array, [:lit, 2], [:lit, 3]], [:str, "2, 3"]],
      [:when, [:array, [:lit, 4]], [:str, "4"]],
      [:str, "else"]]

    expected = [:if,
      [:call, "===", [:lvar, "var"], [:array, [:lit, 1]]],
      [:str, "1"],
      [:if,
        [:or,
          [:call, "===", [:lvar, "var"], [:array, [:lit, 2]]],
          [:call, "===", [:lvar, "var"], [:array, [:lit, 3]]]],
        [:str, "2, 3"],
        [:if,
          [:call, "===", [:lvar, "var"], [:array, [:lit, 4]]],
          [:str, "4"],
          [:str, "else"]]]]

    assert_equal expected, @rewrite.process(input)
  end

  def test_case2
    input = [:case,
     [:lvar, "var"],
     [:when, [:array, [:lit, 1]], [:lasgn, "ret", [:str, "1"]]],
     [:when,
      [:array, [:lit, 2], [:lit, 3], [:lit, 5]],
      [:lasgn, "ret", [:str, "2, 3"]]],
     [:when, [:array, [:lit, 4]], [:lasgn, "ret", [:str, "4"]]],
     [:lasgn, "ret", [:str, "else"]]]

    expected = [:if,
      [:call, "===", [:lvar, "var"], [:array, [:lit, 1]]],
      [:lasgn, "ret", [:str, "1"]],
      [:if,
        [:or,
          [:call, "===", [:lvar, "var"], [:array, [:lit, 2]]],
          [:call, "===", [:lvar, "var"], [:array, [:lit, 3]]],
          [:call, "===", [:lvar, "var"], [:array, [:lit, 5]]]],
        [:lasgn, "ret", [:str, "2, 3"]],
        [:if,
          [:call, "===", [:lvar, "var"], [:array, [:lit, 4]]],
          [:lasgn, "ret", [:str, "4"]],
          [:lasgn, "ret", [:str, "else"]]]]]
    
    assert_equal expected, @rewrite.process(input)
  end

  def test_iter
    input = [[:iter,
        [:call, [:lit, 3], "downto", [:array, [:lit, 1]]],
        [:dasgn_curr, "n"],
        [:fcall, "puts", [:array, [:call, [:dvar, "n"], "to_s"]]]]]
    expected = Sexp.new(Sexp.new(:lasgn, "n", Sexp.new(:lit, 3)),
                        Sexp.new(:while,
                                 Sexp.new(:call,
                                          ">=",
                                          Sexp.new(:lvar, "n"),
                                          Sexp.new(:array, Sexp.new(:lit, 1))),
                                 Sexp.new(:block,
                                          Sexp.new(:call,
                                                   "puts",
                                                   nil,
                                                   Sexp.new(:array,
                                                            Sexp.new(:call,
                                                                     "to_s",
                                                                     Sexp.new(:lvar, "n"),
                                                                     nil))),
                                          Sexp.new(:lasgn, "n", Sexp.new(:call,
                                                                         "-",
                                                                         Sexp.new(:lvar, "n"),
                                                                         Sexp.new(:array, Sexp.new(:lit, 1)))))))
    
    assert_equal expected, @rewrite.process(input)
  end

  def test_when
    input = [:when, [:array, [:lit, 1]], [:str, "1"]]

    expected = [:when, [[:lit, 1]], [:str, "1"]]

    assert_equal expected, @rewrite.process(input)
  end

end
