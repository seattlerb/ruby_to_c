#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'
require 'something'
require 'rewriter'

begin
  require 'rubygems'
  require_gem 'ParseTree'
rescue LoadError
  require 'parse_tree'
end

class TestRewriter < Test::Unit::TestCase

  def setup
    @rewrite = Rewriter.new
  end

  def test_process_call
    input  = [:call, [:lit, 1], :+, [:array, [:lit, 1]]]
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
    expect = [:call, nil, :puts, [:array, [:lit, 1]]]
    assert_equal expect, @rewrite.process(input)
  end

  def test_process_vcall
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
        [:array, [:lit, 1]]],
      [:str, "1"],
      [:if,
        [:or,
          [:call,
            [:lvar, :var],
            :===,
            [:array, [:lit, 2]]],
          [:call,
            [:lvar, :var],
            :===,
            [:array, [:lit, 3]]]],
        [:str, "2, 3"],
        [:if,
          [:call,
            [:lvar, :var],
            :===,
            [:array, [:lit, 4]]],
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

    expected = [:if,
      [:call,
        [:lvar, :var],
        :===,
        [:array, [:lit, 1]]],
      [:lasgn, :ret, [:str, "1"]],
      [:if,
        [:or,
          [:call, [:lvar, :var], :===, [:array, [:lit, 2]]],
          [:call, [:lvar, :var], :===, [:array, [:lit, 3]]],
          [:call, [:lvar, :var], :===, [:array, [:lit, 5]]]],
        [:lasgn, :ret, [:str, "2, 3"]],
        [:if,
          [:call, [:lvar, :var], :===, [:array, [:lit, 4]]],
          [:lasgn, :ret, [:str, "4"]],
          [:lasgn, :ret, [:str, "else"]]]]]
    
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
                     s(:array, s(:lit, 1))),
                   s(:block,
                     s(:call,
                       nil,
                       :puts,
                       s(:array,
                         s(:call,
                           s(:lvar, :n),
                           :to_s,
                           nil))),
                     s(:lasgn, :n, s(:call,
                                      s(:lvar, :n),
                                      :-,
                                      s(:array, s(:lit, 1)))))))
    
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
                       s(:array, s(:lit, 0))),
                     s(:block,
                       s(:dummy,
                         s(:lasgn, :j, s(:lvar, :i)),
                         s(:while,
                           s(:call, s(:lvar, :j), :>=,
                             s(:array, s(:lit, 0))),
                           s(:block,
                             s(:nil),
                             s(:lasgn, :j,
                               s(:call, s(:lvar, :j), :-,
                                 s(:array, s(:lit, 1))))))),
                       s(:lasgn, :i,
                         s(:call, s(:lvar, :i), :-,
                           s(:array, s(:lit, 1))))))))

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
                       s(:array, s(:lit, 0))),
                     s(:block,
                       s(:dummy,
                         s(:lasgn, :j, s(:lvar, :i)),
                         s(:while,
                           s(:call, s(:lvar, :j), :<=,
                             s(:array, s(:lit, 0))),
                           s(:block,
                             s(:nil),
                             s(:lasgn, :j,
                               s(:call, s(:lvar, :j), :+,
                                 s(:array, s(:lit, 1))))))),
                       s(:lasgn, :i,
                         s(:call, s(:lvar, :i), :+,
                           s(:array, s(:lit, 1))))))))

    assert_equal expected, @rewrite.process(input)
  end

  def test_process_until
    input = [:until, [:call, [:lvar, :a], :==, [:array, [:lvar, :b]]], [:fcall, :puts, [:array, [:lit, 2]]]]
    output = s(:while, s(:not, s(:call, s(:lvar, :a), :==, s(:array, s(:lvar, :b)))), s(:call, nil, :puts, s(:array, s(:lit, 2))))
    assert_equal output, @rewrite.process(input)
  end

  def test_process_when
    input = [:when, [:array, [:lit, 1]], [:str, "1"]]

    expected = [:when, [[:lit, 1]], [:str, "1"]]

    assert_equal expected, @rewrite.process(input)
  end

end

class TestRewriter_2 < Test::Unit::TestCase

  # TODO: need a test of interpolated strings

  @@missing = s(nil)
  @@empty = s(:defn, :empty,
      s(:args),
    s(:scope, s(:block, s(:nil))))
  @@stupid = s(:defn, :stupid,
    s(:args),
    s(:scope,
      s(:block,
      s(:return, s(:nil)))))
  @@simple = s(:defn, :simple,
    s(:args, :arg1),
    s(:scope,
      s(:block,
        s(:call, nil, :print, s(:array, s(:lvar, :arg1))),
        s(:call,
          nil,
          :puts,
          s(:array,
            s(:call,
              s(:call, s(:lit, 4), :+, s(:array, s(:lit, 2))),
              :to_s,
              nil))))))
  @@global = s(:defn, :global,
    s(:args),
    s(:scope,
      s(:block,
        s(:call,
          s(:gvar, :$stderr),
          :fputs,
          s(:array, s(:str, "blah"))))))
  @@lasgn_call = s(:defn, :lasgn_call,
    s(:args),
    s(:scope,
      s(:block,
        s(:lasgn, :c,
          s(:call,
            s(:lit, 2),
            :+,
            s(:array, s(:lit, 3)))))))
  @@conditional1 = s(:defn, :conditional1,
    s(:args, :arg1),
    s(:scope,
      s(:block,
        s(:if,
          s(:call,
            s(:lvar, :arg1),
            :==,
            s(:array, s(:lit, 0))),
          s(:return, s(:lit, 1)),
          nil))))
  @@conditional2 = s(:defn, :conditional2,
    s(:args, :arg1),
    s(:scope,
      s(:block,
        s(:if,
          s(:call,
            s(:lvar, :arg1),
            :==,
            s(:array, s(:lit, 0))),
          nil,
          s(:return, s(:lit, 2))))))
  @@conditional3 = s(:defn, :conditional3,
    s(:args, :arg1),
    s(:scope,
      s(:block,
        s(:if,
          s(:call,
            s(:lvar, :arg1),
            :==,
            s(:array, s(:lit, 0))),
          s(:return, s(:lit, 3)),
          s(:return, s(:lit, 4))))))
  @@conditional4 = s(:defn, :conditional4,
    s(:args, :arg1),
    s(:scope,
      s(:block,
        s(:if,
          s(:call,
            s(:lvar, :arg1),
            :==,
            s(:array, s(:lit, 0))),
          s(:return, s(:lit, 2)),
          s(:if,
            s(:call,
              s(:lvar, :arg1),
              :<,
              s(:array, s(:lit, 0))),
            s(:return, s(:lit, 3)),
            s(:return, s(:lit, 4)))))))
  @@iteration1 = s(:defn, :iteration1,
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:lasgn, :array,
                         s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3))),
                       s(:iter,
                         s(:call,
                           s(:lvar, :array),
                           :each,
                           nil),
                         s(:dasgn_curr, :x),
                         s(:call,
                           nil,
                           :puts,
                           s(:array,
                             s(:call,
                               s(:dvar, :x),
                               :to_s,
                               nil)))))))

  @@iteration2 = s(:defn, :iteration2,
                   s(:args), 
                   s(:scope,
                     s(:block,
                       s(:lasgn, :array,
                         s(:array, s(:str, "a"), s(:str, "b"), s(:str, "c"))),
                       s(:iter,
                         s(:call,
                           s(:lvar, :array),
                           :each,
                           nil),
                         s(:dasgn_curr, :x),
                         s(:call,
                           nil,
                           :puts,
                           s(:array,
                             s(:dvar, :x)
                             ))))))

  @@iteration3 = s(:defn, :iteration3,
    s(:args),
    s(:scope,
      s(:block,
        s(:lasgn, :array1,
          s(:array, s(:lit, 1), s(:lit, 2), s(:lit, 3))),
        s(:lasgn, :array2,
          s(:array, s(:lit, 4), s(:lit, 5), s(:lit, 6), s(:lit, 7))),
        s(:iter,
          s(:call,
            s(:lvar, :array1),
            :each,
            nil),
          s(:dasgn_curr, :x),
          s(:iter,
            s(:call,
              s(:lvar, :array2),
              :each,
              nil),
            s(:dasgn_curr, :y),
            s(:block,
              s(:call,
                nil,
                :puts,
                s(:array,
                  s(:call,
                    s(:dvar, :x),
                    :to_s,
                    nil))),
              s(:call,
                nil,
                :puts,
                s(:array,
                  s(:call,
                    s(:dvar, :y),
                    :to_s,
                    nil)))))))))
  @@iteration4 = s(:defn,
                   :iteration4,
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:dummy,
                         s(:lasgn, :n, s(:lit, 1)),
                         s(:while,
                           s(:call,
                             s(:lvar, :n),
                             :<=,
                             s(:array, s(:lit, 3))),
                           s(:block,
                             s(:call,
                               nil,
                               :puts,
                               s(:array,
                                 s(:call,
                                   s(:lvar, :n),
                                   :to_s,
                                   nil))),
                             s(:lasgn,
                               :n,
                               s(:call,
                                 s(:lvar, :n),
                                 :+,
                                 s(:array, s(:lit, 1))))))))))
  @@iteration5 = s(:defn,
                   :iteration5,
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:dummy,
                         s(:lasgn, :n, s(:lit, 3)),
                         s(:while,
                           s(:call, s(:lvar, :n), :>=, s(:array, s(:lit, 1))),
                           s(:block,
                             s(:call, nil, :puts, s(:array, s(:call, s(:lvar, :n), :to_s, nil))),
                             s(:lasgn, :n, s(:call, s(:lvar, :n), :-, s(:array, s(:lit, 1))))))))))
  @@iteration6 = s(:defn,
                   :iteration6,
                   s(:args),
                   s(:scope,
                     s(:block,
                       s(:dummy,
                         s(:lasgn, :temp_var1, s(:lit, 3)),
                         s(:while,
                           s(:call, s(:lvar, :temp_var1), :>=, s(:array, s(:lit, 1))),
                           s(:block,
                             s(:call, nil, :puts, s(:array, s(:str, "hello"))),
                             s(:lasgn,
                               :temp_var1,
                               s(:call, s(:lvar, :temp_var1), :-, s(:array, s(:lit, 1))))))))))
  @@multi_args = s(:defn, :multi_args,
                   s(:args, :arg1, :arg2),
                   s(:scope,
                     s(:block,
                       s(:lasgn, :arg3,
                         s(:call,
                           s(:call,
                             s(:lvar, :arg1),
                             :*,
                             s(:array, s(:lvar, :arg2))),
                           :*,
                           s(:array, s(:lit, 7)))),
                       s(:call,
                         nil,
                         :puts,
                         s(:array,
                           s(:call,
                             s(:lvar, :arg3),
                             :to_s,
                             nil))),
                       s(:return, s(:str, "foo")))))
  @@bools = s(:defn, :bools,
              s(:args, :arg1),
              s(:scope,
                s(:block,
                  s(:if,
                    s(:call,
                      s(:lvar, :arg1),
                      :nil?,
                      nil),
                    s(:return, s(:false)),
                    s(:return, s(:true))))))
  @@case_stmt = s(:defn, :case_stmt,
                  s(:args),
                  s(:scope,
                    s(:block,
                      s(:lasgn, :var, s(:lit, 2)),
                      s(:lasgn, :result, s(:str, "")),
                      s(:if,
                        s(:call,
                          s(:lvar, :var),
                          :===,
                          s(:array, s(:lit, 1))),
                        s(:block,
                          s(:call,
                            nil,
                            :puts,
                            s(:array, s(:str, "something"))),
                          s(:lasgn, :result, s(:str, "red"))),
                        s(:if,
                          s(:or,
                            s(:call,
                              s(:lvar, :var),
                              :===,
                              s(:array, s(:lit, 2))),
                            s(:call,
                              s(:lvar, :var),
                              :===,
                              s(:array, s(:lit, 3)))),
                          s(:lasgn, :result, s(:str, "yellow")),
                          s(:if,
                            s(:call,
                              s(:lvar, :var),
                              :===,
                              s(:array, s(:lit, 4))),
                            nil,
                            s(:lasgn, :result, s(:str, "green"))))),
                      s(:if,
                        s(:call,
                          s(:lvar, :result),
                          :===,
                          s(:array, s(:str, "red"))),
                        s(:lasgn, :var, s(:lit, 1)),
                        s(:if,
                          s(:call,
                            s(:lvar, :result),
                            :===,
                            s(:array, s(:str, "yellow"))),
                          s(:lasgn, :var, s(:lit, 2)),
                          s(:if,
                            s(:call,
                              s(:lvar, :result),
                              :===,
                              s(:array, s(:str, "green"))),
                            s(:lasgn, :var, s(:lit, 3)),
                            nil))),
                      s(:return, s(:lvar, :result)))))
  @@eric_is_stubborn = s(:defn, :eric_is_stubborn,
    s(:args),
    s(:scope,
      s(:block,
        s(:lasgn, :var, s(:lit, 42)),
        s(:lasgn,
          :var2,
          s(:call,
            s(:lvar, :var),
            :to_s,
            nil)),
        s(:call,
          s(:gvar, :$stderr),
          :fputs,
          s(:array, s(:lvar, :var2))),
        s(:return, s(:lvar, :var2)))))
  @@interpolated = s(:defn, :interpolated,
    s(:args),
    s(:scope,
      s(:block,
        s(:lasgn, :var, s(:lit, 14)),
        s(:lasgn, :var2, s(:dstr, "var is ", s(:lvar, :var), s(:str, ". So there."))))))
  @@unknown_args = s(:defn, :unknown_args,
    s(:args, :arg1, :arg2),
    s(:scope,
      s(:block,
        s(:return, s(:lvar, :arg1)))))
  @@determine_args = s(:defn, :determine_args,
                       s(:args),
                       s(:scope,
                         s(:block,
                           s(:call,
                             s(:lit, 5),
                             :==,
                             s(:array,
                               s(:call,
                                 nil,
                                 :unknown_args,
                                 s(:array,
                                   s(:lit, 4), s(:str, "known"))))))))

  @@zarray = s(:defn, :zarray,
               s(:args),
               s(:scope,
                 s(:block, s(:lasgn, :a, s(:array)))))

  @@accessor = s(:defn,
                 :accessor,
                 s(:args),
                 s(:scope, s(:block, s(:return, s(:ivar, :@accessor)))))

  @@accessor_equals = s(:defn,
                        :accessor=,
                        s(:args, :arg),
                        s(:scope,
                          s(:block,
                            s(:return,
                              s(:iasgn, :@accessor, s(:lvar, :arg))))))

  # TODO: sort all vars

  @@bbegin = s(:defn,
               :bbegin,
               s(:args),
               s(:scope,
                 s(:block,
                   s(:begin,
                     s(:ensure,
                       s(:rescue,
                         s(:call, s(:lit, 1), :+, s(:array, s(:lit, 1))),
                         s(:resbody,
                           s(:array, s(:const, :SyntaxError)),
                           s(:block, s(:lasgn, :e1, s(:gvar, :$!)),
                             s(:lit, 2)),
                           s(:resbody,
                             s(:array, s(:const, :Exception)),
                             s(:block, s(:lasgn, :e2, s(:gvar, :$!)),
                               s(:lit, 3)))),
                         s(:lit, 4)),
                       s(:lit, 5))))))

  @@bmethod_added = s(:defn,
                      :bmethod_added,
                      s(:args, :x),
                      s(:scope,
                        s(:block,
                          s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1))))))
  @@dmethod_added = s(:defn,
                      :dmethod_added,
                      s(:args, :x),
                      s(:scope,
                        s(:block,
                          s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1))))))

  @@__all = []

  @@__parser = ParseTree.new
  @@__rewriter = Rewriter.new

  Something.instance_methods(false).sort.each do |meth|
    meth_name = meth.gsub(/=/, '_equals')
    if class_variables.include?("@@#{meth_name}") then
      @@__all << eval("@@#{meth_name}")
      eval "def test_#{meth}
        
        assert_equal @@#{meth_name}, @@__rewriter.process(@@__parser.parse_tree_for_method(Something, :#{meth}))
      end"
    else
      eval "def test_#{meth}; flunk \"You haven't added @@#{meth_name} yet\"; end"
    end
  end

end

class TestR2CRewriter < Test::Unit::TestCase
  def setup
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
