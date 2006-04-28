#!/usr/local/bin/ruby -w

$TESTING = true

begin require 'rubygems' rescue LoadError end
require 'test/unit'
require 'rewriter'
require 'r2ctestcase'
require 'parse_tree'

class TestRewriter < R2CTestCase

  def setup
    @processor = Rewriter.new
    @rewrite = Rewriter.new
  end

  def test_process_call
    input  = [:call, [:lit, 1], :+, [:arglist, [:lit, 1]]]
    expect = input.deep_clone

    assert_equal expect, @rewrite.process(input)
  end

  def test_process_defn_block
    input =  [:defn, :meth, [:scope, [:block, [:args], [:return, [:nil]]]]]
    output = [:defn, :meth, [:args], [:scope, [:block, [:return, [:nil]]]]]

    assert_equal output, @rewrite.process(input)
  end

  def test_process_defn_ivar
    input =  [:defn, :name, [:ivar, :@name]]
    output = [:defn, :name, [:args], [:scope, [:block, [:return, [:ivar, :@name]]]]]

    assert_equal output, @rewrite.process(input)
  end

  def test_process_defn_attrset
    input =  [:defn, :meth, [:attrset, :@name]]
    output = [:defn, :meth, [:args, :arg], [:scope, [:block, [:return, [:iasgn, :@name, [:lvar, :arg]]]]]]

    assert_equal output, @rewrite.process(input)
  end

  def test_process_fcall
    input  = [:fcall, :puts, [:array, [:lit, 1]]]
    expect = [:call, nil, :puts, [:arglist, [:lit, 1]]]
    assert_equal expect, @rewrite.process(input)
  end

  def test_process_vcall_2
    input =  [:vcall, :method]
    output = [:call, nil, :method, nil]

    assert_equal output, @rewrite.process(input)
  end

  def test_process_case
    input = [:case,
      [:lvar, :var],
      [:when, [:array, [:lit, 1]], [:str, "1"]],
      [:when, [:array, [:lit, 2], [:lit, 3]], [:str, "2, 3"]],
      [:when, [:array, [:lit, 4]], [:str, "4"]],
      [:str, "else"]]

    expected = [:if,
      [:call,
        [:lvar, :var],
        :===,
        [:arglist, [:lit, 1]]],
      [:str, "1"],
      [:if,
        [:or,
          [:call,
            [:lvar, :var],
            :===,
            [:arglist, [:lit, 2]]],
          [:call,
            [:lvar, :var],
            :===,
            [:arglist, [:lit, 3]]]],
        [:str, "2, 3"],
        [:if,
          [:call,
            [:lvar, :var],
            :===,
            [:arglist, [:lit, 4]]],
          [:str, "4"],
          [:str, "else"]]]]

    assert_equal expected, @rewrite.process(input)
  end

  def test_process_case_2
    input = [:case,
     [:lvar, :var],
     [:when, [:array, [:lit, 1]], [:lasgn, :ret, [:str, "1"]]],
     [:when,
      [:array, [:lit, 2], [:lit, 3], [:lit, 5]],
      [:lasgn, :ret, [:str, "2, 3"]]],
     [:when, [:array, [:lit, 4]], [:lasgn, :ret, [:str, "4"]]],
     [:lasgn, :ret, [:str, "else"]]]

    expected = s(:if,
      s(:call,
        s(:lvar, :var),
        :===,
        s(:arglist, s(:lit, 1))),
      s(:lasgn, :ret, s(:str, "1")),
      s(:if,
        s(:or,
          s(:call, s(:lvar, :var), :===, s(:arglist, s(:lit, 2))),
          s(:or,
            s(:call, s(:lvar, :var), :===, s(:arglist, s(:lit, 3))),
            s(:call, s(:lvar, :var), :===, s(:arglist, s(:lit, 5))))),
        s(:lasgn, :ret, s(:str, "2, 3")),
        s(:if,
          s(:call, s(:lvar, :var), :===, s(:arglist, s(:lit, 4))),
          s(:lasgn, :ret, s(:str, "4")),
          s(:lasgn, :ret, s(:str, "else")))))
    
    assert_equal expected, @rewrite.process(input)
  end

  def test_process_iter
    input = [:iter,
        [:call, [:lit, 3], :downto, [:array, [:lit, 1]]],
        [:dasgn_curr, :n],
      [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]]
    expected = s(:dummy,
                 s(:lasgn, :n, s(:lit, 3)),
                 s(:while,
                   s(:call,
                     s(:lvar, :n),
                     :>=,
                     s(:arglist, s(:lit, 1))),
                   s(:block,
                     s(:call,
                       nil,
                       :puts,
                       s(:arglist,
                         s(:call,
                           s(:lvar, :n),
                           :to_s,
                           nil))),
                     s(:lasgn, :n, s(:call,
                                      s(:lvar, :n),
                                      :-,
                                      s(:arglist, s(:lit, 1))))), true))
    
    assert_equal expected, @rewrite.process(input)
  end

  def test_iter_downto_nested
    input    = [:block,
                 [:iter,
                   [:call, [:lvar, :n], :downto, [:array, [:lit, 0]]],
                   [:dasgn_curr, :i],
                   [:iter,
                     [:call, [:dvar, :i], :downto, [:array, [:lit, 0]]],
                     [:dasgn_curr, :j],
                     [:nil]]]]

    expected = s(:block,
                 s(:dummy,
                   s(:lasgn, :i, s(:lvar, :n)),
                   s(:while,
                     s(:call, s(:lvar, :i), :>=,
                       s(:arglist, s(:lit, 0))),
                     s(:block,
                       s(:dummy,
                         s(:lasgn, :j, s(:lvar, :i)),
                         s(:while,
                           s(:call, s(:lvar, :j), :>=,
                             s(:arglist, s(:lit, 0))),
                           s(:block,
                             s(:nil),
                             s(:lasgn, :j,
                               s(:call, s(:lvar, :j), :-,
                                 s(:arglist, s(:lit, 1))))), true)),
                       s(:lasgn, :i,
                         s(:call, s(:lvar, :i), :-,
                           s(:arglist, s(:lit, 1))))), true)))

    assert_equal expected, @rewrite.process(input)
  end

  def test_iter_upto_nested
    input    = [:block,
                 [:iter,
                   [:call, [:lvar, :n], :upto, [:array, [:lit, 0]]],
                   [:dasgn_curr, :i],
                   [:iter,
                     [:call, [:dvar, :i], :upto, [:array, [:lit, 0]]],
                     [:dasgn_curr, :j],
                     [:nil]]]]

    expected = s(:block,
                 s(:dummy,
                   s(:lasgn, :i, s(:lvar, :n)),
                   s(:while,
                     s(:call, s(:lvar, :i), :<=,
                       s(:arglist, s(:lit, 0))),
                     s(:block,
                       s(:dummy,
                         s(:lasgn, :j, s(:lvar, :i)),
                         s(:while,
                           s(:call, s(:lvar, :j), :<=,
                             s(:arglist, s(:lit, 0))),
                           s(:block,
                             s(:nil),
                             s(:lasgn, :j,
                               s(:call, s(:lvar, :j), :+,
                                 s(:arglist, s(:lit, 1))))), true)),
                       s(:lasgn, :i,
                         s(:call, s(:lvar, :i), :+,
                           s(:arglist, s(:lit, 1))))), true)))

    assert_equal expected, @rewrite.process(input)
  end

  def test_process_until
    input = [:until,
      [:call,
        [:lvar, :a],
        :==,
        [:array, [:lvar, :b]]],
      [:fcall,
        :puts,
        [:array, [:lit, 2]]],
      true]
    output = s(:while,
               s(:not,
                 s(:call,
                   s(:lvar, :a),
                   :==,
                   s(:arglist, s(:lvar, :b)))),
               s(:call,
                 nil,
                 :puts,
                 s(:arglist, s(:lit, 2))),
               true)
    assert_equal output, @rewrite.process(input)
  end

  def test_process_when
    input = [:when, [:array, [:lit, 1]], [:str, "1"]]

    expected = [:when, [[:lit, 1]], [:str, "1"]]

    assert_equal expected, @rewrite.process(input)
  end
end

class TestR2CRewriter < R2CTestCase

  def setup
    @processor = R2CRewriter.new
    @rewrite = R2CRewriter.new
  end

  def test_process_call_rewritten

    input = t(:call,
              t(:str, "this", Type.str),
              :+,
              t(:array, t(:str, "that", Type.str)),
              Type.str)
    expected = t(:call,
                 nil,
                 :strcat,
                 t(:array,
                   t(:str, "this", Type.str),
                   t(:str, "that", Type.str)),
                 Type.str)

    assert_equal expected, @rewrite.process(input)
  end

  def test_process_call_same

    input = t(:call,
              t(:lit, 1, Type.long),
              :+,
              t(:array, t(:lit, 2, Type.long)),
              Type.long)
    expected = input.deep_clone

    assert_equal expected, @rewrite.process(input)
  end
end
