#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit' if $0 == __FILE__
require 'ruby_to_ruby_c'
require 'r2ctestcase'
require 'unique'

class TestRubyToRubyC < R2CTestCase

  def setup
    @ruby_to_c = RubyToRubyC.new
    @ruby_to_c.env.extend
    @processor = @ruby_to_c
    Unique.reset
  end

  def test_process_dstr
    input  = t(:dstr,
               "var is ",
               t(:lit, 42, Type.long),
               t(:str, ". So there.", Type.str), Type.str)
    output = 'rb_funcall(rb_mKernel, rb_intern("sprintf"), 4, rb_str_new2("%s%s%s"), rb_str_new2("var is "), LONG2NUM(42), rb_str_new2(". So there."))'

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_dxstr
    input  = t(:dxstr,
               "touch ",
               t(:lvar, :x, Type.str), Type.str)
    output = 'rb_funcall(rb_mKernel, rb_intern("`"), 1, rb_funcall(rb_mKernel, rb_intern("sprintf"), 3, rb_str_new2("%s%s"), rb_str_new2("touch "), x))'

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_float
    input  = t(:lit, 1.0, Type.float)
    output = "rb_float_new(1.0)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_iter
    # ruby: arrays.each { ... }
    input = t(:iter,
              t(:call,
                t(:lvar, :arrays, Type.str_list), # should register static
                :each,
                nil, Type.unknown),
              t(:args,
                t(:array, t(:lvar, :arrays, Type.value), Type.void),
                t(:array, t(:lvar, :static_temp_4, Type.value), Type.void),
                Type.void),
              :temp_1)
    output = "static_temp_4 = arrays;
rb_iterate(rb_each, arrays, temp_1, Qnil);
arrays = static_temp_4;"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_defx
    # ruby: this is the ... from arrays.each { ... } 
    input = t(:defx,
              :temp_1,
              t(:args,
                t(:temp_2, Type.str),
                t(:temp_3, Type.value)),
              t(:scope,
                t(:block,
                  t(:lasgn,
                    :arrays,
                    t(:lvar, :static_arrays, Type.value),
                    Type.value),
                  t(:lasgn, :x, t(:lvar, :temp_2, Type.str),
                    Type.str),
                  t(:call,
                    nil,
                    :puts,
                    t(:arglist, t(:dvar, :x, Type.str)), Type.void),
                  t(:lasgn,
                    :static_arrays,
                    t(:lvar, :arrays, Type.value),
                    Type.value),
                  t(:return, t(:nil, Type.value)))), Type.void)

    output = "static VALUE
rrc_c_temp_1(VALUE temp_2, VALUE temp_3) {
VALUE arrays;
VALUE x;
arrays = static_arrays;
x = temp_2;
rb_funcall(self, rb_intern(\"puts\"), 1, x);
static_arrays = arrays;
return Qnil;
}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_long
    input  = t(:lit, 1, Type.long)
    output = "LONG2NUM(1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_range
    input  = t(:lit, 1..42, Type.range)
    output = "rb_range_new(LONG2NUM(1), LONG2NUM(42), 0)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_range_exc
    input  = t(:lit, 1...42, Type.range)
    output = "rb_range_new(LONG2NUM(1), LONG2NUM(42), 1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_regexp
    input  = t(:lit, /x/, Type.regexp)
    output = "rb_reg_new(\"x\", 1, 0)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_regexp_i
    input  = t(:lit, /x|y/i, Type.regexp)
    output = "rb_reg_new(\"x|y\", 3, 1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_sym
    input  = t(:lit, :sym, Type.symbol)
    output = "ID2SYM(rb_intern(\"sym\"))"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_xstr
    input  = t(:xstr, 'touch 5', Type.str)
    output = 'rb_funcall(rb_mKernel, rb_intern("`"), 1, rb_str_new2("touch 5"))'

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_translator
    Object.class_eval "class Suck; end"
    input = [:class, :Suck, :Object,
      [:defn, :something, [:scope, [:block, [:args], [:fcall, :"whaaa\?"]]]],
      [:defn, :foo, [:scope, [:block, [:args], [:vcall, :something]]]]]
    expected = "// class Suck < Object\n\nstatic VALUE\nrrc_c_something(VALUE self) {\nrb_funcall(self, rb_intern(\"whaaa?\"), 0);\n}\n\nstatic VALUE\nrrc_c_foo(VALUE self) {\nrb_funcall(self, rb_intern(\"something\"), 0);\n}"
    assert_equal expected, RubyToRubyC.translator.process(input)
  end

end
