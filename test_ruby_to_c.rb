#!/usr/local/bin/ruby -w

require 'test/unit'
require 'ruby_to_c'
require 'parse_tree'
require 'something'

class TestRubyToC < Test::Unit::TestCase

  def setup
    @ruby_to_c = RubyToC.new
    @ruby_to_c.env.extend
  end

  def test_args
    input =  Sexp.new(:args,
                      Sexp.new("foo", Type.long),
                      Sexp.new("bar", Type.long))
    output = "(long foo, long bar)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_args_empty
    input =  Sexp.new(:args)
    output = "()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_array_single
    input  = Sexp.new(:array,
                      Sexp.new(:lvar, "arg1", Type.long))
    output = "arg1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_array_multiple
    input  = Sexp.new(:array,
                      Sexp.new(:lvar, "arg1", Type.long),
                      Sexp.new(:lvar, "arg2", Type.long))
    output = "arg1, arg2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call
    input  = Sexp.new(:call, "name", nil, nil)
    output = "name()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_lhs
    input  = Sexp.new(:call, "name", Sexp.new(:lit, 1), nil)
    output = "name(1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_lhs_rhs
    input  = Sexp.new(:call,
                      "name",
                      Sexp.new(:lit, 1),
                      Sexp.new(:array,
                               Sexp.new(:str, "foo")))
    output = "name(1, \"foo\")"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_rhs
    input  = Sexp.new(:call,
                      "name",
                      nil,
                      Sexp.new(:array,
                               Sexp.new(:str, "foo")))
    output = "name(\"foo\")"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_nil?
    input  = Sexp.new(:call, "nil?", Sexp.new(:lvar, "arg", Type.long), nil)
    output = "NIL_P(arg)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_operator
    methods = Sexp.new("==", "<", ">", "-", "+", "*", "/", "%", "<=", ">=")

    methods.each do |method|
      input  = Sexp.new(:call,
                        method,
                        Sexp.new(:lit, 1),
                        Sexp.new(:array, Sexp.new(:lit, 2)))
      output = "1 #{method} 2"

      assert_equal output, @ruby_to_c.process(input)
    end
  end

  def test_block
    input  = Sexp.new(:block, Sexp.new(:return, Sexp.new(:nil)))
    output = "return Qnil;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_block_multiple
    input  = Sexp.new(:block,
                      Sexp.new(:str, "foo"),
                      Sexp.new(:return, Sexp.new(:nil)))
    output = "\"foo\";\nreturn Qnil;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_dasgn
    input  = Sexp.new(:dasgn_curr, "x", Type.long)
    output = "x"

    assert_equal output, @ruby_to_c.process(input)
    # HACK - see test_type_checker equivalent test
    # assert_equal Type.long, @ruby_to_c.env.lookup("x")
  end

  def test_defn
    input  = Sexp.new(:defn,
                      "empty",
                      Sexp.new(:args),
                      Sexp.new(:scope),
                      Type.function([], Type.void))
    output = "void\nempty() {\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_defn_with_args_and_body
    input  = Sexp.new(:defn, "empty",
                      Sexp.new(:args,
                               Sexp.new("foo", Type.long),
                               Sexp.new("bar", Type.long)),
                      Sexp.new(:scope,
                               Sexp.new(:block,
                                        Sexp.new(:lit, 5))),
                      Type.function([], Type.void))
    output = "void\nempty(long foo, long bar) {\n5;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def disabled_test_dstr
    input  = Sexp.new(:dstr,
                      "var is ",
                      Sexp.new(:lvar, "var"),
                      Sexp.new(:str, ". So there."))
    output = "sprintf stuff goes here"

    flunk "Way too hard right now"
    assert_equal output, @ruby_to_c.process(input)
  end

  def test_dvar
    input  = Sexp.new(:dvar, "dvar", Type.long)
    output = "dvar"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_false
    input =  Sexp.new(:false)
    output = "Qfalse"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_gvar
    input  = Sexp.new(:gvar, "$stderr", Type.long)
    output = "stderr"

    assert_equal output, @ruby_to_c.process(input)
    assert_raises RuntimeError do
      @ruby_to_c.process Sexp.new(:gvar, "$some_gvar", Type.long)
    end
  end

  def test_if
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               "==",
                               Sexp.new(:lit, 1),
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      Sexp.new(:str, "not equal"),
                      nil)
    output = "if (1 == 2) {\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_if_else
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               "==",
                               Sexp.new(:lit, 1),
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      Sexp.new(:str, "not equal"),
                      Sexp.new(:str, "equal"))
    output = "if (1 == 2) {\n\"not equal\";\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_if_block
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               "==",
                               Sexp.new(:lit, 1),
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      Sexp.new(:block,
                               Sexp.new(:lit, 5),
                               Sexp.new(:str, "not equal")),
                      nil)
    output = "if (1 == 2) {\n5;\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_iter
    var_type = Type.long_list
    input  = Sexp.new(:iter,
                      Sexp.new(:call,
                               "each",
                               Sexp.new(:lvar, "array", var_type), nil),
                      Sexp.new(:dasgn_curr, "x", Type.long),
                      Sexp.new(:call,
                               "puts",
                               nil,
                               Sexp.new(:array,
                                        Sexp.new(:call,
                                                 "to_s",
                                                 Sexp.new(:dvar,
                                                          "x",
                                                          Type.long),
                                                 nil))))
    output = "unsigned long index_x;
for (index_x = 0; index_x < array.length; ++index_x) {
long x = array.contents[index_x];
puts(to_s(x));
}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_lasgn
    input  = Sexp.new(:lasgn, "var", Sexp.new(:str, "foo"), Type.str)
    output = "var = \"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_lasgn_array
    input  = Sexp.new(:lasgn,
                      "var",
                      Sexp.new(:array,
                               Sexp.new(:str, "foo"),
                               Sexp.new(:str, "bar")),
                      Type.str_list)
    output = "var.contents = { \"foo\", \"bar\" };\nvar.length = 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_lit
    input  = Sexp.new(:lit, 1)
    output = "1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_lvar
    input  = Sexp.new(:lvar, "arg", Type.long)
    output = "arg"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_nil
    input  = Sexp.new(:nil)
    output = "Qnil"

    assert_equal output, @ruby_to_c.process(input)
  end


  def test_or
    input  = Sexp.new(:or, Sexp.new(:lit, 1), Sexp.new(:lit, 2))
    output = "1 || 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_return
    input =  Sexp.new(:return, Sexp.new(:nil))
    output = "return Qnil"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_str
    input  = Sexp.new(:str, "foo")
    output = "\"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_scope
    input =  Sexp.new(:scope,
                      Sexp.new(:block,
                               Sexp.new(:return, Sexp.new(:nil))))
    output = "{\nreturn Qnil;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_scope_empty
    input  = Sexp.new(:scope)
    output = "{\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_scope_var_set
    input  = Sexp.new(:scope, Sexp.new(:block,
                                       Sexp.new(:lasgn, "arg",
                                                Sexp.new(:str, "declare me"),
                                                Type.str),
                                       Sexp.new(:return, Sexp.new(:nil))))
    output = "{\nchar * arg;\narg = \"declare me\";\nreturn Qnil;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_true
    input =  Sexp.new(:true)
    output = "Qtrue"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_unless
    input  = Sexp.new(:if, Sexp.new(:call, "==",
                                    Sexp.new(:lit, 1),
                                    Sexp.new(:array, Sexp.new(:lit, 2))),
                      nil,
                      Sexp.new(:str, "equal"))
    output = "if (1 == 2) {\n;\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  @@empty = "void
empty() {
}"
  # TODO: this test is not good... the args should type-resolve or raise
  # TODO: this test is good, we should know that print takes objects... or something
  @@simple = "void
simple(char * arg1) {
print(arg1);
puts(to_s(4 + 2));
}"
  @@stupid = "VALUE
stupid() {
return Qnil;
}"
  @@global = "void
global() {
fputs(stderr, \"blah\");
}"
  @@lasgn_call = "void
lasgn_call() {
long c;
c = 2 + 3;
}"
  @@conditional1 = "long
conditional1(long arg1) {
if (arg1 == 0) {
return 1;
}
}"
  @@conditional2 = "long
conditional2(long arg1) {
if (arg1 == 0) {
;
} else {
return 2;
}
}"
  @@conditional3 = "long
conditional3(long arg1) {
if (arg1 == 0) {
return 3;
} else {
return 4;
}
}"
  @@conditional4 = "long
conditional4(long arg1) {
if (arg1 == 0) {
return 2;
} else {
if (arg1 < 0) {
return 3;
} else {
return 4;
}
}
}"
  @@iteration1 = "void
iteration1() {
long_array array;
array.contents = { 1, 2, 3 };
array.length = 3;
unsigned long index_x;
for (index_x = 0; index_x < array.length; ++index_x) {
long x = array.contents[index_x];
puts(to_s(x));
}
}"
  @@iteration2 = "void
iteration2() {
long_array array;
array.contents = { 1, 2, 3 };
array.length = 3;
unsigned long index_x;
for (index_x = 0; index_x < array.length; ++index_x) {
long x = array.contents[index_x];
puts(to_s(x));
}
}"
  @@iteration3 = "void
iteration3() {
long_array array1;
long_array array2;
array1.contents = { 1, 2, 3 };
array1.length = 3;
array2.contents = { 4, 5, 6, 7 };
array2.length = 4;
unsigned long index_x;
for (index_x = 0; index_x < array1.length; ++index_x) {
long x = array1.contents[index_x];
unsigned long index_y;
for (index_y = 0; index_y < array2.length; ++index_y) {
long y = array2.contents[index_y];
puts(to_s(x));
puts(to_s(y));
}
}
}"
  @@multi_args = "char *
multi_args(long arg1, long arg2) {
long arg3;
arg3 = arg1 * arg2 * 7;
puts(to_s(arg3));
return \"foo\";
}"
  @@bools = "long
bools(VALUE arg1) {
if (NIL_P(arg1)) {
return Qfalse;
} else {
return Qtrue;
}
}"
# HACK: I don't like the semis after the if blocks, but it is a compromise right now
  @@case_stmt = "char *
case_stmt() {
char * result;
long var;
var = 2;
result = \"\";
if (case_equal_long(var, 1)) {
puts(\"something\");
result = \"red\";
} else {
if (case_equal_long(var, 2) || case_equal_long(var, 3)) {
result = \"yellow\";
} else {
if (case_equal_long(var, 4)) {
;
} else {
result = \"green\";
}
}
};
if (case_equal_str(result, \"red\")) {
var = 1;
} else {
if (case_equal_str(result, \"yellow\")) {
var = 2;
} else {
if (case_equal_str(result, \"green\")) {
var = 3;
}
}
};
return result;
}"
# HACK fputs emits arguments in the wrong order
  @@eric_is_stubborn = "char *
eric_is_stubborn() {
long var;
char * var2;
var = 42;
var2 = to_s(var);
fputs(stderr, var2);
return var2;
}"
  @@determine_args = "void
determine_args() {
5 == unknown_args(4, \"known\");
}"
  @@unknown_args = "long
unknown_args(long arg1, char * arg2) {
return arg1;
}"

  @@__all = Sexp.new()
  @@__expect_raise = Sexp.new( "interpolated" )

  Something.instance_methods(false).sort.each do |meth|
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}
        exp = RubyToC.translate Something, :#{meth}
        assert_equal @@#{meth}, exp
      end"
    else
      if @@__expect_raise.include? meth then
        eval "def test_#{meth}
        assert_raise(SyntaxError) { RubyToC.translate Something, :#{meth} }; end"
      else
        eval "def test_#{meth}; flunk \"You haven't added @@#{meth} yet\"; end"
      end
    end
  end

  def ztest_class
    assert_equal(@@__all.join("\n\n"),
		 RubyToC.translate_all_of(Something))
  end

end
