#!/usr/local/bin/ruby -w

require 'test/unit'
require 'ruby_to_c'
require 'parse_tree'
require 'something'

class TestTypeMap < Test::Unit::TestCase
  def test_c_type
    raise NotImplementedError, 'Need to write test_c_type'
  end
end

class TestRubyToC < Test::Unit::TestCase

  def setup
    @ruby_to_c = RubyToC.new
    @ruby_to_c.env.extend
  end

  def test_env
    raise NotImplementedError, 'Need to write test_env'
  end

  def test_prototypes
    raise NotImplementedError, 'Need to write test_prototypes'
  end

  def test_prototypes=
    raise NotImplementedError, 'Need to write test_prototypes='
  end

  def test_process_args_normal
    input =  Sexp.new(:args,
                      Sexp.new("foo", Type.long),
                      Sexp.new("bar", Type.long))
    output = "(long foo, long bar)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_args_empty
    input =  Sexp.new(:args)
    output = "()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_array_single
    input  = Sexp.new(:array,
                      Sexp.new(:lvar, "arg1", Type.long))
    output = "arg1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_array_multiple
    input  = Sexp.new(:array,
                      Sexp.new(:lvar, "arg1", Type.long),
                      Sexp.new(:lvar, "arg2", Type.long))
    output = "arg1, arg2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call
    input  = Sexp.new(:call, nil, "name", nil)
    output = "name()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_lhs
    input  = Sexp.new(:call, Sexp.new(:lit, 1), "name", nil)
    output = "name(1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_lhs_rhs
    input  = Sexp.new(:call,
                      Sexp.new(:lit, 1),
                      "name",
                      Sexp.new(:array, Sexp.new(:str, "foo")))
    output = "name(1, \"foo\")"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_rhs
    input  = Sexp.new(:call,
                      nil,
                      "name",
                      Sexp.new(:array,
                               Sexp.new(:str, "foo")))
    output = "name(\"foo\")"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_nil?
    input  = Sexp.new(:call,
                      Sexp.new(:lvar, "arg", Type.long),
                      "nil?",
                      nil)
    output = "NIL_P(arg)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_operator
    methods = Sexp.new("==", "<", ">", "-", "+", "*", "/", "%", "<=", ">=")

    methods.each do |method|
      input  = Sexp.new(:call,
                        Sexp.new(:lit, 1),
                        method,
                        Sexp.new(:array, Sexp.new(:lit, 2)))
      output = "1 #{method} 2"

      assert_equal output, @ruby_to_c.process(input)
    end
  end

  def test_process_block
    input  = Sexp.new(:block, Sexp.new(:return, Sexp.new(:nil)))
    output = "return Qnil;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_block_multiple
    input  = Sexp.new(:block,
                      Sexp.new(:str, "foo"),
                      Sexp.new(:return, Sexp.new(:nil)))
    output = "\"foo\";\nreturn Qnil;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_dasgn_curr
    input  = Sexp.new(:dasgn_curr, "x", Type.long)
    output = "x"

    assert_equal output, @ruby_to_c.process(input)
    # HACK - see test_type_checker equivalent test
    # assert_equal Type.long, @ruby_to_c.env.lookup("x")
  end

  def test_process_defn
    input  = Sexp.new(:defn,
                      "empty",
                      Sexp.new(:args),
                      Sexp.new(:scope),
                      Type.function([], Type.void))
    output = "void\nempty() {\n}"
    assert_equal output, @ruby_to_c.process(input)

    assert_equal ["void empty();\n"], @ruby_to_c.prototypes

  end

  def test_process_defn_with_args_and_body
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

  def test_process_dvar
    input  = Sexp.new(:dvar, "dvar", Type.long)
    output = "dvar"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_false
    input =  Sexp.new(:false)
    output = "Qfalse"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_gvar
    input  = Sexp.new(:gvar, "$stderr", Type.long)
    output = "stderr"

    assert_equal output, @ruby_to_c.process(input)
    assert_raises RuntimeError do
      @ruby_to_c.process Sexp.new(:gvar, "$some_gvar", Type.long)
    end
  end

  def test_process_if
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               Sexp.new(:lit, 1),
                               "==",
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      Sexp.new(:str, "not equal"),
                      nil)
    output = "if (1 == 2) {\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_if_else
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               Sexp.new(:lit, 1),
                               "==",
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      Sexp.new(:str, "not equal"),
                      Sexp.new(:str, "equal"))
    output = "if (1 == 2) {\n\"not equal\";\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_if_block
    input  = Sexp.new(:if,
                      Sexp.new(:call,
                               Sexp.new(:lit, 1),
                               "==",
                               Sexp.new(:array, Sexp.new(:lit, 2))),
                      Sexp.new(:block,
                               Sexp.new(:lit, 5),
                               Sexp.new(:str, "not equal")),
                      nil)
    output = "if (1 == 2) {\n5;\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_iter
    var_type = Type.long_list
    input  = Sexp.new(:iter,
                      Sexp.new(:call,
                               Sexp.new(:lvar, "array", var_type),
                               "each",
                               nil),
                      Sexp.new(:dasgn_curr, "x", Type.long),
                      Sexp.new(:call,
                               nil,
                               "puts",
                               Sexp.new(:array,
                                        Sexp.new(:call,
                                                 Sexp.new(:dvar,
                                                          "x",
                                                          Type.long),
                                                 "to_s",
                                                 nil))))
    output = "unsigned long index_x;
for (index_x = 0; index_x < array.length; ++index_x) {
long x = array.contents[index_x];
puts(to_s(x));
}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lasgn
    input  = Sexp.new(:lasgn, "var", Sexp.new(:str, "foo"), Type.str)
    output = "var = \"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lasgn_array
    input  = Sexp.new(:lasgn,
                      "var",
                      Sexp.new(:array,
                               Sexp.new(:str, "foo"),
                               Sexp.new(:str, "bar")),
                      Type.str_list)
    output = "var.length = 2;
var.contents = (long*) malloc(sizeof(long) * var.length);
var.contents[0] = \"foo\";
var.contents[1] = \"bar\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit
    input  = Sexp.new(:lit, 1)
    output = "1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lvar
    input  = Sexp.new(:lvar, "arg", Type.long)
    output = "arg"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_nil
    input  = Sexp.new(:nil)
    output = "Qnil"

    assert_equal output, @ruby_to_c.process(input)
  end


  def test_process_or
    input  = Sexp.new(:or, Sexp.new(:lit, 1), Sexp.new(:lit, 2))
    output = "1 || 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_return
    input =  Sexp.new(:return, Sexp.new(:nil))
    output = "return Qnil"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_str
    input  = Sexp.new(:str, "foo")
    output = "\"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_scope
    input =  Sexp.new(:scope,
                      Sexp.new(:block,
                               Sexp.new(:return, Sexp.new(:nil))))
    output = "{\nreturn Qnil;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_scope_empty
    input  = Sexp.new(:scope)
    output = "{\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_scope_var_set
    input  = Sexp.new(:scope, Sexp.new(:block,
                                       Sexp.new(:lasgn, "arg",
                                                Sexp.new(:str, "declare me"),
                                                Type.str),
                                       Sexp.new(:return, Sexp.new(:nil))))
    output = "{\nchar * arg;\narg = \"declare me\";\nreturn Qnil;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_true
    input =  Sexp.new(:true)
    output = "Qtrue"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_unless
    input  = Sexp.new(:if, Sexp.new(:call,
                                    Sexp.new(:lit, 1),
                                    "==",
                                    Sexp.new(:array, Sexp.new(:lit, 2))),
                      nil,
                      Sexp.new(:str, "equal"))
    output = "if (1 == 2) {\n;\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_while
    raise NotImplementedError, 'Need to write test_process_while'
  end
end

class TestRubyToC_2 < Test::Unit::TestCase # ZenTest SKIP

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
array.length = 3;
array.contents = (long*) malloc(sizeof(long) * array.length);
array.contents[0] = 1;
array.contents[1] = 2;
array.contents[2] = 3;
unsigned long index_x;
for (index_x = 0; index_x < array.length; ++index_x) {
long x = array.contents[index_x];
puts(to_s(x));
}
}"
  @@iteration2 = "void
iteration2() {
long_array array;
array.length = 3;
array.contents = (long*) malloc(sizeof(long) * array.length);
array.contents[0] = 1;
array.contents[1] = 2;
array.contents[2] = 3;
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
array1.length = 3;
array1.contents = (long*) malloc(sizeof(long) * array1.length);
array1.contents[0] = 1;
array1.contents[1] = 2;
array1.contents[2] = 3;
array2.length = 4;
array2.contents = (long*) malloc(sizeof(long) * array2.length);
array2.contents[0] = 4;
array2.contents[1] = 5;
array2.contents[2] = 6;
array2.contents[3] = 7;
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
  @@iteration4 = "void
iteration4() {
long n;
n = 1;
while (n <= 3) {
puts(to_s(n));
n = n + 1;
}
}"
  @@iteration5 = "void
iteration5() {
long n;
n = 3;
while (n >= 1) {
puts(to_s(n));
n = n - 1;
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
