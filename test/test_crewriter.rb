$TESTING = true

begin require 'rubygems'; rescue LoadError; end
require 'test/unit' if $0 == __FILE__
require 'crewriter'
require 'r2ctestcase'

class TestCRewriter < R2CTestCase

  def setup
    @processor = CRewriter.new
    @rewrite = CRewriter.new
    Unique.reset
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

  def test_process_class
    input  = t(:class,
               :IterExample,
               :Object,
               t(:defn,
                 :example,
                 t(:args),
                 t(:scope,
                   t(:block,
                     t(:lasgn, :sum, t(:lit, 0, Type.long), Type.long),
                     t(:iter,
                       t(:call,
                         t(:lit, 0...10, Type.range),
                         :each,
                         nil, Type.void),
                       t(:dasgn_curr, :a, Type.long),
                       t(:iter,
                         t(:call,
                           t(:lit, 0...10, Type.range),
                           :each,
                           nil, Type.void),
                         t(:dasgn_curr, :b, Type.long),
                         t(:lasgn,
                           :sum,
                           t(:call,
                             t(:lvar, :sum, Type.long),
                             :+,
                             t(:arglist,
                               t(:call,
                                 t(:dvar, :a, Type.long),
                                 :+,
                                 t(:arglist, t(:dvar, :b, Type.long)),
                                 Type.void)),
                             Type.void),
                           Type.long))),
                     t(:return, t(:lvar, :sum, Type.long)))), Type.void))

    expect = t(:class,
               :IterExample,
               :Object,
               t(:defx,
                 :temp_2,
                 t(:args, :temp_3, :temp_4),
                 t(:scope,
                   t(:block,
                     t(:lasgn,
                       :sum,
                       t(:call,
                         t(:lvar, :sum, Type.long),
                         :+,
                         t(:arglist,
                           t(:call,
                             t(:dvar, :a, Type.long),
                             :+,
                             t(:arglist, t(:dvar, :b, Type.long)), Type.void)
                           ), Type.void), Type.long))), Type.void),
               t(:defx,
                 :temp_1,
                 t(:args, :temp_5, :temp_6),
                 t(:scope,
                   t(:block,
                     t(:iter,
                       t(:call,
                         t(:lit, 0...10, Type.range),
                         :each,
                         nil, Type.void),
                       t(:args,
                         t(:array, t(:dasgn_curr, :b, Type.long)),
                         t(:array, t(:lvar, :sum, Type.value))), # HACK
                       :temp_2))), Type.void),
               t(:defn,
                 :example,
                 t(:args),
                 t(:scope,
                   t(:block,
                     t(:lasgn, :sum, t(:lit, 0, Type.long), Type.long),
                     t(:iter,
                       t(:call,
                         t(:lit, 0...10, Type.range),
                         :each,
                         nil, Type.void),
                       t(:args,
                         t(:array, t(:dasgn_curr, :a, Type.long)),
                         t(:array)),
                       :temp_1),
                       t(:return, t(:lvar, :sum, Type.long)))), Type.void))

    assert_equal expect, @rewrite.process(input)
  end

  def test_process_lasgn
    input  = t(:lasgn, :variable, t(:nil), Type.long)
    expect = t(:lasgn, :variable, t(:nil), Type.long)

    assert_equal expect, @rewrite.process(input)
    assert_equal [], @rewrite.free
    assert_equal [:variable], @rewrite.env.all.keys
  end

  def test_process_lvar
    input  = t(:lvar, :variable, Type.long)
    expect = t(:lvar, :variable, Type.long)

    assert_equal expect, @rewrite.process(input)
    assert_equal [[:variable, Type.value]], @rewrite.free # HACK
    assert_equal [:variable], @rewrite.env.all.keys
  end

  def test_process_iter_each
    # sum = 0; arr.each do |value| sum += value; end
    input  = t(:block,
               t(:lasgn, :arr, t(:array, t(:lit, 1, Type.long)), Type.long_list),
               t(:lasgn, :sum, t(:lit, 0, Type.long), Type.long),
               t(:iter,
                 t(:call, t(:lvar, :arr, Type.long), :each, nil, Type.void),
                 t(:dasgn_curr, :value, Type.long),
                 t(:lasgn, # block guts
                   :sum,
                   t(:call,
                     t(:lvar, :sum, Type.long),
                     :+,
                     t(:arglist, t(:dvar, :value, Type.long)), Type.void),
                   Type.long), Type.void), Type.void)

    # $sum = sum; arr.each do |value| temp_1(value) end
    # def temp_1(value) sum = $sum; ...; $sum = sum; end

    expect = t(:block,
               t(:lasgn, :arr, t(:array, t(:lit, 1, Type.long)), Type.long_list),
               t(:lasgn, :sum, t(:lit, 0, Type.long), Type.long),
               t(:iter, # new iter
                 t(:call, t(:lvar, :arr, Type.long), :each, nil, Type.void),
                 t(:args,
                   t(:array, t(:dasgn_curr, :value, Type.long)),
                   t(:array, t(:lvar, :sum, Type.long))),
                 :temp_1), Type.void)

    assert_equal expect, @rewrite.process(input)

    defx = t(:defx,
             :temp_1,
             t(:args, :temp_2, :temp_3),
             t(:scope,
               t(:block,
                 t(:lasgn, :sum, # sum =
                   t(:call,
                     t(:lvar, :sum, Type.long), # sum + value
                     :+,
                     t(:arglist, t(:dvar, :value, Type.long)), Type.void),
                   Type.long))), Type.void)

    assert_equal [defx], @rewrite.iter_functions
  end

  def test_process_iter_each_with_index
    input  = t(:block,
               t(:lasgn, :arr, t(:array, t(:lit, 1, Type.long)), Type.long),
               t(:lasgn, :sum, t(:lit, 0, Type.long), Type.long),
               t(:iter,
                 t(:call,
                   t(:lvar, :arr, Type.long),
                   :each_with_index,
                   nil, Type.void),
                 t(:masgn,
                   t(:array,
                     t(:dasgn_curr, :value, Type.long),
                     t(:dasgn_curr, :i, Type.long))),
                     t(:lasgn, # block guts
                       :sum,
                       t(:call,
                         t(:lvar, :sum, Type.long),
                         :+,
                         t(:arglist, t(:dvar, :value, Type.long)), Type.void),
                       Type.long)))

    expect = t(:block,
               t(:lasgn, :arr, t(:array, t(:lit, 1, Type.long)), Type.long),
               t(:lasgn, :sum, t(:lit, 0, Type.long), Type.long),
               t(:iter, # new iter
                 t(:call,
                   t(:lvar, :arr, Type.long),
                   :each_with_index,
                   nil, Type.void),
                 t(:args,
                   t(:array,
                     t(:dasgn_curr, :value, Type.long),
                     t(:dasgn_curr, :i, Type.long)),
                   t(:array,
                     t(:lvar, :sum, Type.long))),
                   :temp_1))

    assert_equal expect, @rewrite.process(input)

    defx = t(:defx,
             :temp_1,
             t(:args, :temp_2, :temp_3),
             t(:scope,
               t(:block,
                 t(:lasgn, :sum, # sum =
                   t(:call,
                     t(:lvar, :sum, Type.long), # sum + value
                     :+,
                     t(:arglist, t(:dvar, :value, Type.long)), Type.void),
                   Type.long))), Type.void)

    assert_equal [defx], @rewrite.iter_functions
  end

  def test_free
    e = @rewrite.env
    e.add :sum, Type.value
    e.set_val :sum, true
    e.extend
    e.add :arr, Type.value
    e.set_val :arr, true
    
    expected = {:arr=>[Type.value, true], :sum=>[Type.value, true]}
    assert_equal expected, e.all

    expected = [{:arr=>[Type.value, true]}, {:sum=>[Type.value, true]}]
    assert_equal expected, e.env

    assert_equal [[:arr, Type.value]], @rewrite.free
  end

  def test_var_names_in
    assert_equal [[:value, Type.long]], @rewrite.var_names_in(t(:dasgn_curr, :value, Type.long))

    input  = t(:masgn, t(:array,
                         t(:dasgn_curr, :value, Type.long),
                         t(:dasgn_curr, :i, Type.str)))
    expect = [[:value, Type.long], [:i, Type.str]]

    assert_equal expect, @rewrite.var_names_in(input)
  end
end

