#!/usr/local/bin/ruby -w

$TESTING = true

begin require 'rubygems'; rescue LoadError; end
require 'test/unit' if $0 == __FILE__
require 'iter_rewriter'
require 'r2ctestcase'
require 'parse_tree'

class TestIterRewriter < R2CTestCase

  def setup
    @processor = IterRewriter.new
    @iter_rewrite = IterRewriter.new
    Unique.reset
  end

  def test_process_class
    input  = s(:class,
               :IterExample,
               :Object,
               s(:defn,
                 :example,
                 s(:args),
                 s(:scope,
                   s(:block,
                     s(:lasgn, :sum, s(:lit, 0)),
                     s(:iter,
                       s(:call, s(:lit, 0...10), :each, nil),
                       s(:dasgn_curr, :a),
                       s(:iter,
                         s(:call, s(:lit, 0...10), :each, nil),
                         s(:dasgn_curr, :b),
                         s(:lasgn,
                           :sum,
                           s(:call,
                             s(:lvar, :sum),
                             :+,
                             s(:arglist,
                               s(:call,
                                 s(:dvar, :a),
                                 :+,
                                 s(:arglist, s(:dvar, :b)))))))),
                     s(:return, s(:lvar, :sum))))))

    expect = s(:class,
               :IterExample,
               :Object,
               s(:defx,
                 :temp_2,
                 s(:args, :temp_3, :temp_4),
                 s(:scope,
                   s(:block,
                     s(:lasgn,
                       :sum,
                       s(:call,
                         s(:lvar, :sum),
                         :+,
                         s(:arglist,
                           s(:call,
                             s(:dvar, :a),
                             :+,
                             s(:arglist, s(:dvar, :b))))))))),
               s(:defx,
                 :temp_1,
                 s(:args, :temp_5, :temp_6),
                 s(:scope,
                   s(:block,
                     s(:iter,
                       s(:call, s(:lit, 0...10), :each, nil),
                       s(:args,
                         s(:array,
                           s(:dasgn_curr, :b)), s(:array, s(:lvar, :sum))),
                       :temp_2)))),
               s(:defn,
                 :example,
                 s(:args),
                 s(:scope,
                   s(:block,
                     s(:lasgn, :sum, s(:lit, 0)),
                     s(:iter,
                       s(:call, s(:lit, 0...10), :each, nil),
                       s(:args,
                         s(:array, s(:dasgn_curr, :a)),
                         s(:array)), :temp_1),
                       s(:return, s(:lvar, :sum))))))

    assert_equal expect, @iter_rewrite.process(input)
  end

  def test_process_lasgn
    input  = s(:lasgn, :variable, s(:nil))
    expect = s(:lasgn, :variable, s(:nil))

    assert_equal expect, @iter_rewrite.process(input)
    assert_equal [], @iter_rewrite.free
    assert_equal [:variable], @iter_rewrite.env.all.keys
  end

  def test_process_lvar
    input  = s(:lvar, :variable)
    expect = s(:lvar, :variable)

    assert_equal expect, @iter_rewrite.process(input)
    assert_equal [:variable], @iter_rewrite.free
    assert_equal [:variable], @iter_rewrite.env.all.keys
  end

  def test_process_iter_each
    # sum = 0; arr.each do |value| sum += value; end
    input  = s(:block,
               s(:lasgn, :arr, s(:array, s(:lit, 1))),
               s(:lasgn, :sum, s(:lit, 0)),
               s(:iter,
                 s(:call, s(:lvar, :arr), :each, nil),
                 s(:dasgn_curr, :value),
                 s(:lasgn, # block guts
                   :sum,
                   s(:call,
                     s(:lvar, :sum), :+, s(:arglist, s(:dvar, :value))))))

    # $sum = sum; arr.each do |value| temp_1(value) end
    # def temp_1(value) sum = $sum; ...; $sum = sum; end

    expect = s(:block,
               s(:lasgn, :arr, s(:array, s(:lit, 1))),
               s(:lasgn, :sum, s(:lit, 0)),
               s(:iter, # new iter
                 s(:call, s(:lvar, :arr), :each, nil),
                 s(:args,
                   s(:array, s(:dasgn_curr, :value)),
                   s(:array, s(:lvar, :sum))),
                 :temp_1))

    assert_equal expect, @iter_rewrite.process(input)

    defx = s(:defx,
             :temp_1,
             s(:args, :temp_2, :temp_3),
             s(:scope,
               s(:block,
                 s(:lasgn, :sum, # sum =
                   s(:call,
                     s(:lvar, :sum), # sum + value
                     :+,
                     s(:arglist, s(:dvar, :value)))))))

    assert_equal [defx], @iter_rewrite.iter_functions
  end

  def test_process_iter_each_with_index
    input  = s(:block,
               s(:lasgn, :arr, s(:array, s(:lit, 1))),
               s(:lasgn, :sum, s(:lit, 0)),
               s(:iter,
                 s(:call, s(:lvar, :arr), :each_with_index, nil),
                 s(:masgn,
                   s(:array,
                     s(:dasgn_curr, :value), s(:dasgn_curr, :i))),
                     s(:lasgn, # block guts
                       :sum,
                       s(:call, s(:lvar, :sum), :+,
                       s(:arglist, s(:dvar, :value))))))

    expect = s(:block,
               s(:lasgn, :arr, s(:array, s(:lit, 1))),
               s(:lasgn, :sum, s(:lit, 0)),
               s(:iter, # new iter
                 s(:call, s(:lvar, :arr), :each_with_index, nil),
                 s(:args,
                   s(:array,
                     s(:dasgn_curr, :value),
                     s(:dasgn_curr, :i)),
                   s(:array,
                     s(:lvar, :sum))),
                   :temp_1))

    assert_equal expect, @iter_rewrite.process(input)

    defx = s(:defx,
             :temp_1,
             s(:args, :temp_2, :temp_3),
             s(:scope,
               s(:block,
                 s(:lasgn, :sum, # sum =
                   s(:call,
                     s(:lvar, :sum), # sum + value
                     :+,
                     s(:arglist, s(:dvar, :value)))))))

    assert_equal [defx], @iter_rewrite.iter_functions
  end

  def test_var_names_in
    assert_equal [:value], @iter_rewrite.var_names_in(s(:dasgn_curr, :value))

    input  = s(:masgn, s(:array, s(:dasgn_curr, :value), s(:dasgn_curr, :i)))
    expect = [:value, :i]

    assert_equal expect, @iter_rewrite.var_names_in(input)
  end

end

