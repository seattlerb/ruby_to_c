#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'
require 'ruby_to_c'
require 'something'

class TestTypeMap < Test::Unit::TestCase

  def test_c_type_long
    assert_equal "long", TypeMap.c_type(Type.long)
  end

  def test_c_type_long_list
    assert_equal "long_array", TypeMap.c_type(Type.long_list)
  end

  def test_c_type_str
    assert_equal "str", TypeMap.c_type(Type.str)
  end

  def test_c_type_str_list
    assert_equal "str_array", TypeMap.c_type(Type.str_list)
  end

  def test_c_type_bool
    assert_equal "long", TypeMap.c_type(Type.bool)
  end

  def test_c_type_void
    assert_equal "void", TypeMap.c_type(Type.void)
  end

  def test_c_type_value
    assert_equal "VALUE", TypeMap.c_type(Type.value)
  end

  def test_c_type_unknown
    assert_equal "VALUE", TypeMap.c_type(Type.unknown)
  end
end

class TestRubyToC < Test::Unit::TestCase

  def setup
    @ruby_to_c = RubyToC.new
    @ruby_to_c.env.extend
  end

  def test_and
    input  = t(:and, t(:lit, 1), t(:lit, 2))
    output = "1 && 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_env
    assert_not_nil @ruby_to_c.env
    assert_kind_of Environment, @ruby_to_c.env
  end

  def test_prototypes
    assert_equal [], @ruby_to_c.prototypes
    @ruby_to_c.process t(:defn,
                         :empty,
                         t(:args),
                         t(:scope),
                         Type.function([], Type.void))

    assert_equal "void empty();\n", @ruby_to_c.prototypes.first
  end

  def test_process_args_normal
    input =  t(:args,
               t(:foo, Type.long),
               t(:bar, Type.long))
    output = "(long foo, long bar)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_args_empty
    input =  t(:args)
    output = "()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_array_single
    input  = t(:array,
               t(:lvar, :arg1, Type.long))
    output = "arg1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_array_multiple
    input  = t(:array,
               t(:lvar, :arg1, Type.long),
               t(:lvar, :arg2, Type.long))
    output = "arg1, arg2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call
    input  = t(:call, nil, :name, nil)
    output = "name()"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_lhs
    input  = t(:call, t(:lit, 1), :name, nil)
    output = "name(1)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_lhs_rhs
    input  = t(:call,
               t(:lit, 1),
               :name,
               t(:array, t(:str, "foo")))
    output = "name(1, \"foo\")"

    assert_equal output, @ruby_to_c.process(input)
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

  def test_process_call_nil?
    input  = t(:call,
               t(:lvar, :arg, Type.long),
               :nil?,
               nil)
    output = "NIL_P(arg)"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_call_operator
    methods = t(:==, :<, :>, :-, :+, :*, :/, :%, :<=, :>=)

    methods.each do |method|
      input  = t(:call,
                 t(:lit, 1),
                 method,
                 t(:array, t(:lit, 2)))
      output = "1 #{method} 2"

      assert_equal output, @ruby_to_c.process(input)
    end
  end

  def test_process_block
    input  = t(:block, t(:return, t(:nil)))
    output = "return Qnil;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_block_multiple
    input  = t(:block,
               t(:str, "foo"),
               t(:return, t(:nil)))
    output = "\"foo\";\nreturn Qnil;\n"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_dasgn_curr
    input  = t(:dasgn_curr, :x, Type.long)
    output = "x"

    assert_equal output, @ruby_to_c.process(input)
    # HACK - see test_type_checker equivalent test
    # assert_equal Type.long, @ruby_to_c.env.lookup("x")
  end

  # TODO: fix for 1.8.2
  def test_process_defn
    input  = t(:defn,
               :empty,
               t(:args),
               t(:scope),
               Type.function([], Type.void))
    output = "void\nempty() {\n}"
    assert_equal output, @ruby_to_c.process(input)

    assert_equal ["void empty();\n"], @ruby_to_c.prototypes

  end

  def test_process_defn_with_args_and_body
    input  = t(:defn, :empty,
               t(:args,
                 t(:foo, Type.long),
                 t(:bar, Type.long)),
               t(:scope,
                 t(:block,
                   t(:lit, 5))),
               Type.function([], Type.void))
    output = "void\nempty(long foo, long bar) {\n5;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def disabled_test_dstr
    input  = t(:dstr,
               "var is ",
               t(:lvar, :var),
               t(:str, ". So there."))
    output = "sprintf stuff goes here"

    flunk "Way too hard right now"
    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_dvar
    input  = t(:dvar, :dvar, Type.long)
    output = "dvar"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_false
    input =  t(:false)
    output = "Qfalse"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_gvar
    input  = t(:gvar, :$stderr, Type.long)
    output = "stderr"

    assert_equal output, @ruby_to_c.process(input)
    assert_raises RuntimeError do
      @ruby_to_c.process t(:gvar, :$some_gvar, Type.long)
    end
  end

  def test_process_if
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:array, t(:lit, 2))),
               t(:str, "not equal"),
               nil)
    output = "if (1 == 2) {\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_if_else
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:array, t(:lit, 2))),
               t(:str, "not equal"),
               t(:str, "equal"))
    output = "if (1 == 2) {\n\"not equal\";\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_if_block
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:array, t(:lit, 2))),
               t(:block,
                 t(:lit, 5),
                 t(:str, "not equal")),
               nil)
    output = "if (1 == 2) {\n5;\n\"not equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_iter
    var_type = Type.long_list
    input  = t(:iter,
               t(:call,
                 t(:lvar, :array, var_type),
                 :each,
                 nil),
               t(:dasgn_curr, :x, Type.long),
               t(:call,
                 nil,
                 :puts,
                 t(:array,
                   t(:call,
                     t(:dvar,
                       :x,
                       Type.long),
                     :to_s,
                     nil))))
    output = "unsigned long index_x;
for (index_x = 0; index_x < array.length; ++index_x) {
long x = array.contents[index_x];
puts(to_s(x));
}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lasgn
    input  = t(:lasgn, :var, t(:str, "foo"), Type.str)
    output = "var = \"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lasgn_array
    input  = t(:lasgn,
               :var,
               t(:array,
                 t(:str, "foo", Type.str),
                 t(:str, "bar", Type.str)),
               Type.str_list)
    output = "var.length = 2;
var.contents = (str*) malloc(sizeof(str) * var.length);
var.contents[0] = \"foo\";
var.contents[1] = \"bar\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lit
    input  = t(:lit, 1)
    output = "1"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_lvar
    input  = t(:lvar, :arg, Type.long)
    output = "arg"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_nil
    input  = t(:nil)
    output = "Qnil"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_or
    input  = t(:or, t(:lit, 1), t(:lit, 2))
    output = "1 || 2"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_return
    input =  t(:return, t(:nil))
    output = "return Qnil"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_str
    input  = t(:str, "foo", Type.str)
    output = "\"foo\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_str_multi
    input  = t(:str, "foo
bar", Type.str)
    output = "\"foo\\nbar\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_str_backslashed
    input  = t(:str, "foo\nbar", Type.str)
    output = "\"foo\\nbar\""

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_scope
    input =  t(:scope,
               t(:block,
                 t(:return, t(:nil))))
    output = "{\nreturn Qnil;\n}"

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
                           Type.str),
                         t(:return, t(:nil))))
    output = "{\nstr arg;\narg = \"declare me\";\nreturn Qnil;\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_true
    input =  t(:true)
    output = "Qtrue"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_unless
    input  = t(:if,
               t(:call,
                 t(:lit, 1),
                 :==,
                 t(:array, t(:lit, 2))),
               nil,
               t(:str, "equal"))
    output = "if (1 == 2) {\n;\n} else {\n\"equal\";\n}"

    assert_equal output, @ruby_to_c.process(input)
  end

  def test_process_while
    input = t(:while,
              t(:call, t(:lvar, :n), :<=, t(:array, t(:lit, 3))),
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
                      t(:lit, 1))),
                  Type.long))) # NOTE Type.long needed but not used

    expected = "while (n <= 3) {\nputs(to_s(n));\nn = n + 1;\n}"

    assert_equal expected, @ruby_to_c.process(input)
  end
end

class TestRubyToCSomething < Test::Unit::TestCase # ZenTest SKIP

  @@empty = "void
empty() {
Qnil;
}"
  # TODO: this test is not good... the args should type-resolve or raise
  # TODO: this test is good, we should know that print takes objects... or something
  @@simple = "void
simple(str arg1) {
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
str_array array;
array.length = 3;
array.contents = (str*) malloc(sizeof(str) * array.length);
array.contents[0] = \"a\";
array.contents[1] = \"b\";
array.contents[2] = \"c\";
unsigned long index_x;
for (index_x = 0; index_x < array.length; ++index_x) {
str x = array.contents[index_x];
puts(x);
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
  @@iteration6 = "void
iteration6() {
long temp_var1;
temp_var1 = 3;
while (temp_var1 >= 1) {
puts(\"hello\");
temp_var1 = temp_var1 - 1;
}
}"
  @@multi_args = "str
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
  @@case_stmt = "str
case_stmt() {
str result;
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
  @@eric_is_stubborn = "str
eric_is_stubborn() {
long var;
str var2;
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
unknown_args(long arg1, str arg2) {
return arg1;
}"

  @@whiles = "void
whiles() {
while (Qfalse) {
puts(\"false\")
};
{
puts(\"true\")
} while (Qfalse);
}"

  # TODO: we need to do something w/ said array because this is dumb:
  @@zarray = "void
zarray() {
VALUE_array a;
a.length = 0;
a.contents = (long*) malloc(sizeof(long) * a.length);
}"

  # TODO: sort all vars

  @@bmethod_added = "void\nbmethod_added(long x) {\nx + 1;\n}"
  @@dmethod_added = "void\ndmethod_added(long x) {\nx + 1;\n}"

  @@__all = []
  @@__expect_raise = [ "interpolated", "bbegin" ]
  @@__skip = [ "accessor", "accessor=" ]

  @@__ruby_to_c = RubyToC.translator
  @@__ruby_to_c.processors[1].genv
  @@__ruby_to_c.processors[1].genv.add :SyntaxError, Type.fucked
  @@__ruby_to_c.processors[1].genv.add :Exception, Type.fucked

  Something.instance_methods(false).sort.each do |meth|
    next if @@__skip.include? meth                     
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}
        exp = @@__ruby_to_c.process ParseTree.new.parse_tree_for_method(Something, :#{meth})
        assert_equal @@#{meth}, exp
      end"
    else
      if @@__expect_raise.include? meth then
        eval "def test_#{meth}
        assert_raise(UnsupportedNodeError) { @@__ruby_to_c.process ParseTree.new.parse_tree_for_method(Something, :#{meth}) }; end"
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
