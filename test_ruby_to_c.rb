#!/usr/local/bin/ruby -w

require 'test/unit'
require 'ruby_to_c'
require 'something'

class TestRubyToC < Test::Unit::TestCase

  @@empty = "void
empty() {
}"
  # TODO: this test is not good... the args should type-resolve or raise
  # TODO: this test is good, we should know that print takes objects... or something
  @@simple = "void
simple(VALUE arg1) {
print(arg1);
puts(4 + 2);
}"
  @@stupid = "VALUE
stupid() {
return Qnil;
}"
  @@global = "void
global() {
fputs(\"blah\", stderr);
}"
  @@lasgn_call = "void
lasgn_call() {
long c = 2 + 3;
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
puts(x);
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
puts(x);
}
}"
  @@iteration3 = "void
iteration3() {
long_array array1;
array1.contents = { 1, 2, 3 };
array1.length = 3;
long_array array2;
array2.contents = { 4, 5, 6, 7 };
array2.length = 4;
unsigned long index_x;
for (index_x = 0; index_x < array1.length; ++index_x) {
long x = array1.contents[index_x];
unsigned long index_y;
for (index_y = 0; index_y < array2.length; ++index_y) {
long y = array2.contents[index_y];
puts(x);
puts(y);
}
}
}"
  @@multi_args = "char *
multi_args(long arg1, long arg2) {
long arg3 = arg1 * arg2 * 7;
puts(arg3);
return \"foo\";
}"
  @@bools = "long
bools(VALUE arg1) {
if (NIL_P(arg1)) {
return 0;
} else {
return 1;
}
}"
# HACK: I don't like the semis after the if blocks, but it is a compromise right now
  @@case_stmt = "char *
case_stmt() {
long var = 2;
char * result = \"\";
if (var == 1) {
puts(\"something\");
result = \"red\";
} else {
if (var == 2 || var == 3) {
result = \"yellow\";
} else {
if (var == 4) {
;
} else {
result = \"green\";
}
}
};
if (result == \"red\") {
var = 1;
} else {
if (result == \"yellow\") {
var = 2;
} else {
if (result == \"green\") {
var = 3;
}
}
};
return result;
}"
  @@eric_is_stubborn = "char *
eric_is_stubborn() {
long var = 42;
char * var2 = sprintf(\"%ld\", var);
fputs(var2, stderr);
return var2;
}"

  @@__all = []
  @@__expect_raise = [ "interpolated" ]

  Something.instance_methods(false).sort.each do |meth|
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}; assert_equal @@#{meth}, RubyToC.translate(Something, :#{meth}); end"
    else
      if @@__expect_raise.include? meth then
        eval "def test_#{meth}; assert_raise(SyntaxError) { RubyToC.translate(Something, :#{meth}) }; end"
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
