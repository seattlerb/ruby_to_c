#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'ruby_to_ansi_c'
require 'r2ctestcase'

class TestRubyToAnsiC < R2CTestCase
  def setup
    @ruby_to_c = RubyToAnsiC.new
    @ruby_to_c.env.extend
    @processor = @ruby_to_c
  end

  def test_c_type_bool
    assert_equal "bool", @ruby_to_c.class.c_type(CType.bool)
  end

  def test_c_type_float
    assert_equal "double", @ruby_to_c.class.c_type(CType.float)
  end

  def test_c_type_long
    assert_equal "long", @ruby_to_c.class.c_type(CType.long)
  end

  def test_c_type_long_list
    assert_equal "long *", @ruby_to_c.class.c_type(CType.long_list)
  end

  def test_c_type_str
    assert_equal "str", @ruby_to_c.class.c_type(CType.str)
  end

  def test_c_type_str_list
    assert_equal "str *", @ruby_to_c.class.c_type(CType.str_list)
  end

  def test_c_type_symbol
    assert_equal "symbol", @ruby_to_c.class.c_type(CType.symbol)
  end

  def test_c_type_unknown
    assert_equal "void *", @ruby_to_c.class.c_type(CType.unknown)
  end

  def test_c_type_value
    assert_equal "void *", @ruby_to_c.class.c_type(CType.value)
  end

  def test_c_type_void
    assert_equal "void", @ruby_to_c.class.c_type(CType.void)
  end

  def test_env
    refute_nil @ruby_to_c.env
    assert_kind_of RubyParserStuff::Environment, @ruby_to_c.env
  end

  def test_process_and
    input  = t(:and, t(:lit, 1, CType.long), t(:lit, 2, CType.long))
    output = "1 && 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_args_empty
    input =  t(:args)
    output = "()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_args_normal
    input =  t(:args,
               t(:foo, CType.long),
               t(:bar, CType.long))
    output = "(long foo, long bar)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_array_empty
    input  = t(:array)
    output = "rb_ary_new()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_array_multiple
    input  = t(:array,
               t(:lvar, :arg1, CType.long),
               t(:lvar, :arg2, CType.long))
    output = "arg1, arg2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_array_single
    input  = t(:array,
               t(:lvar, :arg1, CType.long))
    output = "arg1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_block
    input  = t(:block, t(:return, t(:nil)))
    output = "return NULL;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_block_multiple
    input  = t(:block,
               t(:str, "foo"),
               t(:return, t(:nil)))
    output = "\"foo\";\nreturn NULL;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call
    input  = t(:call, nil, :name, nil)
    output = "name()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_lhs
    input  = t(:call, t(:lit, 1, CType.long), :name, nil)
    output = "name(1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_lhs_rhs
    input  = t(:call,
               t(:lit, 1, CType.long),
               :name,
               t(:array, t(:str, "foo")))
    output = "name(1, \"foo\")"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_nil?
    input  = t(:call,
               t(:lvar, :arg, CType.long),
               :nil?,
               nil)
    output = "arg"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_operator
    methods = t(:==, :<, :>, :-, :+, :*, :/, :%, :<=, :>=)

    methods.each do |method|
      input  = t(:call,
                 t(:lit, 1, CType.long),
                 method,
                 t(:array, t(:lit, 2, CType.long)))
      output = "1 #{method} 2"

      assert_equal output, @ruby_to_c.process(input)
    end
  end

  def test_process_call_rhs
    input  = t(:call,
               nil,
               :name,
               t(:array,
                 t(:str, "foo")))
    output = "name(\"foo\")"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_dasgn_curr
    input  = t(:dasgn_curr, :x, CType.long)
    output = "x"

    assert_equal output, @ruby_to_c.process(input)
    # HACK - see test_type_checker equivalent test
    # assert_equal CType.long, @ruby_to_c.env.lookup("x")
  end

  # TODO: fix for 1.8.2
  def test_process_defn
    input  = t(:defn,
               :empty,
               t(:args),
               t(:scope),
               CType.function([], CType.void))
    output = "void\nempty() {\n}"
    assert_equal output, @ruby_to_c.process(input)

    assert_equal ["void empty();\n"], @ruby_to_c.prototypes

  end

  def test_process_defn_with_args_and_body
    input  = t(:defn, :empty,
               t(:args,
                 t(:foo, CType.long),
                 t(:bar, CType.long)),
               t(:scope,
                 t(:block,
                   t(:lit, 5, CType.long))),
               CType.function([], CType.void))
    output = "void\nempty(long foo, long bar) {\n5;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_dvar
    input  = t(:dvar, :dvar, CType.long)
    output = "dvar"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_false
    input =  t(:false)
    output = "0"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_gvar
    input  = t(:gvar, :$stderr, CType.long)
    output = "stderr"

    assert_equal output, @ruby_to_c.process(input)
    assert_raises RuntimeError do
      @ruby_to_c.process t(:gvar, :$some_gvar, CType.long)
    end
  end

  def test_process_iasgn
    input = t(:iasgn, :@blah, t(:lit, 42, CType.long), CType.long)
    expected = "self->blah = 42"

    assert_equal expected, @ruby_to_c.process(input)
  end

  def test_process_if
    input  = t(:if,
               t(:call,
                 t(:lit, 1, CType.long),
                 :==,
                 t(:array, t(:lit, 2, CType.long))),
               t(:str, "not equal"),
               nil)
    output = "if (1 == 2) {\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_if_block
    input  = t(:if,
               t(:call,
                 t(:lit, 1, CType.long),
                 :==,
                 t(:array, t(:lit, 2, CType.long))),
               t(:block,
                 t(:lit, 5, CType.long),
                 t(:str, "not equal")),
               nil)
    output = "if (1 == 2) {\n5;\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_if_else
    input  = t(:if,
               t(:call,
                 t(:lit, 1, CType.long),
                 :==,
                 t(:array, t(:lit, 2, CType.long))),
               t(:str, "not equal"),
               t(:str, "equal"))
    output = "if (1 == 2) {\n\"not equal\";\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_ivar
    @ruby_to_c.env.add :@blah, CType.long 
    input = t(:ivar, :@blah, CType.long)
    expected = "self->blah"

    assert_equal expected, @ruby_to_c.process(input)
  end

  def test_process_lasgn
    input  = t(:lasgn, :var, t(:str, "foo"), CType.str)
    output = "var = \"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_float
    input  = t(:lit, 1.0, CType.float)
    output = "1.0"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_long
    input  = t(:lit, 1, CType.long)
    output = "1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_sym
    input  = t(:lit, :sym, CType.symbol)
    output = "\"sym\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lvar
    input  = t(:lvar, :arg, CType.long)
    output = "arg"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_nil
    input  = t(:nil)
    output = "NULL"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_not
    input  = t(:not, t(:true, CType.bool), CType.bool)
    output = "!(1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_or
    input  = t(:or, t(:lit, 1, CType.long), t(:lit, 2, CType.long))
    output = "1 || 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_return
    input =  t(:return, t(:nil))
    output = "return NULL"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_scope
    input =  t(:scope,
               t(:block,
                 t(:return, t(:nil))))
    output = "{\nreturn NULL;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_scope_empty
    input  = t(:scope)
    output = "{\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_scope_var_set
    input  = t(:scope, t(:block,
                         t(:lasgn, :arg,
                           t(:str, "declare me"),
                           CType.str),
                         t(:return, t(:nil))))
    output = "{\nstr arg;\narg = \"declare me\";\nreturn NULL;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_str
    input  = t(:str, "foo", CType.str)
    output = "\"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_str_backslashed
    input  = t(:str, "foo\nbar", CType.str)
    output = "\"foo\\nbar\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_str_multi
    input  = t(:str, "foo
bar", CType.str)
    output = "\"foo\\nbar\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_true
    input =  t(:true)
    output = "1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_unless
    input  = t(:if,
               t(:call,
                 t(:lit, 1, CType.long),
                 :==,
                 t(:array, t(:lit, 2, CType.long))),
               nil,
               t(:str, "equal"))
    output = "if (1 == 2) {\n;\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_while
    input = t(:while,
              t(:call, t(:lvar, :n), :<=, t(:array, t(:lit, 3, CType.long))),
              t(:block,
                t(:call,
                  nil,
                  :puts,
                  t(:array,
                    t(:call,
                      t(:lvar, :n),
                      :to_s,
                      nil))),
                t(:lasgn, :n,
                  t(:call,
                    t(:lvar, :n),
                    :+,
                    t(:array,
                      t(:lit, 1, CType.long))),
                  CType.long)), true) # NOTE CType.long needed but not used

    expected = "while (n <= 3) {\nputs(to_s(n));\nn = n + 1;\n}"

    assert_equal expected, @ruby_to_c.process(input)
  end

  def test_prototypes
    assert_equal [], @ruby_to_c.prototypes
    @ruby_to_c.process t(:defn,
                         :empty,
                         t(:args),
                         t(:scope),
                         CType.function([], CType.void))

    assert_equal "void empty();\n", @ruby_to_c.prototypes.first
  end

#   def test_translator
#     Object.class_eval "class Suck; end"
#     input = [:class, :Suck, :Object,
#       [:defn, :something, [:scope, [:block, [:args], [:fcall, :"whaaa\?"]]]],
#       [:defn, :foo, [:scope, [:block, [:args], [:vcall, :something]]]]]
#     expected = "// class Suck < Object\n\nvoid\nsomething() {\nwhaaa?();\n}\n\nvoid\nfoo() {\nsomething();\n}"
#     assert_equal expected, RubyToAnsiC.translator.process(input)
#   end

  def disabled_test_dstr
    input  = t(:dstr,
               "var is ",
               t(:lvar, :var),
               t(:str, ". So there."))
    output = "sprintf stuff goes here"

    flunk "Way too hard right now"
    assert_equal output, @ruby_to_c.process(input)
  end
end
