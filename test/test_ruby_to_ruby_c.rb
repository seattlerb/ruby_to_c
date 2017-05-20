#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
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
               t(:lit, 42, CType.long),
               t(:str, ". So there.", CType.str), CType.str)
    output = 'rb_funcall(rb_mKernel, rb_intern("sprintf"), 4, rb_str_new2("%s%s%s"), rb_str_new2("var is "), LONG2NUM(42), rb_str_new2(". So there."))'

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_dxstr
    input  = t(:dxstr,
               "touch ",
               t(:lvar, :x, CType.str), CType.str)
    output = 'rb_funcall(rb_mKernel, rb_intern("`"), 1, rb_funcall(rb_mKernel, rb_intern("sprintf"), 3, rb_str_new2("%s%s"), rb_str_new2("touch "), x))'

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_float
    input  = t(:lit, 1.0, CType.float)
    output = "rb_float_new(1.0)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_iter
    # ruby: arrays.each { ... }
    input = t(:iter,
              t(:call,
                t(:lvar, :arrays, CType.str_list), # should register static
                :each,
                nil, CType.unknown),
              t(:args,
                t(:array, t(:lvar, :arrays, CType.value), CType.void),
                t(:array, t(:lvar, :static_temp_4, CType.value), CType.void),
                CType.void),
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
                t(:temp_2, CType.str),
                t(:temp_3, CType.value)),
              t(:scope,
                t(:block,
                  t(:lasgn,
                    :arrays,
                    t(:lvar, :static_arrays, CType.value),
                    CType.value),
                  t(:lasgn, :x, t(:lvar, :temp_2, CType.str),
                    CType.str),
                  t(:call,
                    nil,
                    :puts,
                    t(:arglist, t(:dvar, :x, CType.str)), CType.void),
                  t(:lasgn,
                    :static_arrays,
                    t(:lvar, :arrays, CType.value),
                    CType.value),
                  t(:return, t(:nil, CType.value)))), CType.void)

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
    input  = t(:lit, 1, CType.long)
    output = "LONG2NUM(1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_range
    input  = t(:lit, 1..42, CType.range)
    output = "rb_range_new(LONG2NUM(1), LONG2NUM(42), 0)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_range_exc
    input  = t(:lit, 1...42, CType.range)
    output = "rb_range_new(LONG2NUM(1), LONG2NUM(42), 1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_regexp
    input  = t(:lit, /x/, CType.regexp)
    output = "rb_reg_new(\"x\", 1, 0)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_regexp_i
    input  = t(:lit, /x|y/i, CType.regexp)
    output = "rb_reg_new(\"x|y\", 3, 1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit_sym
    input  = t(:lit, :sym, CType.symbol)
    output = "ID2SYM(rb_intern(\"sym\"))"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_xstr
    input  = t(:xstr, 'touch 5', CType.str)
    output = 'rb_funcall(rb_mKernel, rb_intern("`"), 1, rb_str_new2("touch 5"))'

    assert_equal output, @ruby_to_c.process(input)
  end

#   def test_translator
#     Object.class_eval "class Suck; end"
#     input = [:class, :Suck, :Object,
#       [:defn, :something, [:scope, [:block, [:args], [:fcall, :"whaaa\?"]]]],
#       [:defn, :foo, [:scope, [:block, [:args], [:vcall, :something]]]]]
#     expected = "// class Suck < Object\n\nstatic VALUE\nrrc_c_something(VALUE self) {\nrb_funcall(self, rb_intern(\"whaaa?\"), 0);\n}\n\nstatic VALUE\nrrc_c_foo(VALUE self) {\nrb_funcall(self, rb_intern(\"something\"), 0);\n}"
#     assert_equal expected, RubyToRubyC.translator.process(input)
#   end

end
