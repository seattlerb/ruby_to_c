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
    input =  Sexp.from_array [:args, ["foo", Type.long], ["bar", Type.long]]
    output = "(long foo, long bar)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_args_empty
    input =  Sexp.from_array [:args]
    output = "()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_array_single
    input  = Sexp.from_array [:array, [:lvar, "arg1", Type.long]]
    output = "arg1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_array_multiple
    input  = Sexp.from_array [:array, [:lvar, "arg1", Type.long], [:lvar, "arg2", Type.long]]
    output = "arg1, arg2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call
    input  = Sexp.from_array [:call, "name", nil, nil]
    output = "name()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_lhs
    input  = Sexp.from_array [:call, "name", [:lit, 1], nil]
    output = "name(1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_lhs_rhs
    input  = Sexp.from_array [:call, "name", [:lit, 1], [:array, [:str, "foo"]]]
    output = "name(1, \"foo\")"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_rhs
    input  = Sexp.from_array [:call, "name", nil, [:array, [:str, "foo"]]]
    output = "name(\"foo\")"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_nil?
    input  = Sexp.from_array [:call, "nil?", [:lvar, "arg", Type.long], nil]
    output = "NIL_P(arg)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_call_operator
    methods = ["==", "<", ">", "-", "+", "*", "/", "%", "<=", ">="]

    methods.each do |method|
      input  = Sexp.from_array [:call, method, [:lit, 1], [:array, [:lit, 2]]]
      output = "1 #{method} 2"

      assert_equal output, @ruby_to_c.process(input)
    end
  end

  def test_block
    input  = Sexp.from_array [:block, [:return, [:nil]]]
    output = "return Qnil;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_block_multiple
    input  = Sexp.from_array [:block, [:str, "foo"], [:return, [:nil]]]
    output = "\"foo\";\nreturn Qnil;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_dasgn
    input  = Sexp.from_array [:dasgn_curr, "x", Type.long]
    output = "x"

    assert_equal output, @ruby_to_c.process(input)
    # HACK - see test_type_checker equivalent test
    # assert_equal Type.long, @ruby_to_c.env.lookup("x")
  end

  def test_defn
    function_type = Type.function [], Type.void
    input  = Sexp.from_array [:defn, "empty", [:args], [:scope], function_type]
    output = "void\nempty() {\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_defn_with_args_and_body
    function_type = Type.function [], Type.void
    input  = Sexp.from_array [:defn, "empty",
                     [:args, ["foo", Type.long], ["bar", Type.long]],
                     [:scope, [:block, [:lit, 5]]],
                     function_type]
    output = "void\nempty(long foo, long bar) {\n5;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def disabled_test_dstr
    input  = Sexp.from_array [:dstr, "var is ", [:lvar, "var"], [:str, ". So there."]]
    output = "sprintf stuff goes here"

    flunk "Way too hard right now"
    assert_equal output, @ruby_to_c.process(input)
  end

  def test_dvar
    input  = Sexp.from_array [:dvar, "dvar", Type.long]
    output = "dvar"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_false
    input =  [:false]
    output = "Qfalse"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_gvar
    input  = Sexp.from_array [:gvar, "$stderr", Type.long]
    output = "stderr"

    assert_equal output, @ruby_to_c.process(input)
    assert_raises RuntimeError do
      @ruby_to_c.process Sexp.from_array([:gvar, "$some_gvar", Type.long])
    end
  end

  def test_if
    input  = Sexp.from_array [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                   [:str, "not equal"],
                   nil]
    output = "if (1 == 2) {\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_if_else
    input  = Sexp.from_array [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                   [:str, "not equal"],
                   [:str, "equal"]]
    output = "if (1 == 2) {\n\"not equal\";\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_if_block
    input  = Sexp.from_array [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                   [:block, [:lit, 5], [:str, "not equal"]],
                   nil]
    output = "if (1 == 2) {\n5;\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_iter
    var_type = Type.long_list
    input  = Sexp.from_array [:iter,
               [:call, "each", [:lvar, "array", var_type], nil],
               [:dasgn_curr, "x", Type.long],
               [:call, "puts", nil, [:array,
                 [:call, "to_s", [:dvar, "x", Type.long], nil]]]]
    output = "unsigned long index_x;
for (index_x = 0; index_x < array.length; ++index_x) {
long x = array.contents[index_x];
puts(to_s(x));
}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_lasgn
    input  = Sexp.from_array [:lasgn, "var", [:str, "foo"], Type.str]
    output = "var = \"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end
  
  def test_lasgn_array
    input  = Sexp.from_array [:lasgn, "var", [:array, [:str, "foo"], [:str, "bar"]],
                      Type.str_list]
    output = "var.contents = { \"foo\", \"bar\" };\nvar.length = 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_lit
    input  = Sexp.from_array [:lit, 1]
    output = "1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_lvar
    input  = Sexp.from_array [:lvar, "arg", Type.long]
    output = "arg"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_nil
    input  = Sexp.from_array [:nil]
    output = "Qnil"

    assert_equal output, @ruby_to_c.process(input)
  end


  def test_or
    input  = Sexp.from_array [:or, [:lit, 1], [:lit, 2]]
    output = "1 || 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_return
    input =  [:return, [:nil]]
    output = "return Qnil"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_str
    input  = Sexp.from_array [:str, "foo"]
    output = "\"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_scope
    input =  [:scope, [:block, [:return, [:nil]]]]
    output = "{\nreturn Qnil;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_scope_empty
    input  = Sexp.from_array [:scope]
    output = "{\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_scope_var_set
    input  = Sexp.from_array([:scope, [:block, [:lasgn, "arg", [:str, "declare me"], Type.str], [:return, [:nil]]]])
    output = "{\nchar * arg;\narg = \"declare me\";\nreturn Qnil;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_true
    input =  [:true]
    output = "Qtrue"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_unless
    input  = Sexp.from_array [:if, [:call, "==", [:lit, 1], [:array, [:lit, 2]]],
                   nil,
                   [:str, "equal"]]
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

  @@__all = []
  @@__expect_raise = [ "interpolated" ]

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
