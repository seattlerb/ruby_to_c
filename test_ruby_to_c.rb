#!/usr/local/bin/ruby -w

require 'test/unit'
require 'ruby_to_c'
require 'something'

class TestRubyToC < Test::Unit::TestCase

  @@empty = "void
empty() {
}"
  @@simple = "void
simple(long arg1) {
print(arg1);
puts(4 + 2);
}"
  @@conditional = "long
conditional(long arg1) {
if (arg1 == 0) {
return 2;
} else {
if (arg1 < 0) {
return 3;
} else {
return 4;
};
};
}"
  @@iteration1 = "void
iteration1() {
long array[] = { 1, 2, 3 };
unsigned long index;
for (index = 0; index < 3; ++index) {
long x = array[index];
puts(x);
};
}"
  @@iteration2 = "void
iteration2() {
long array[] = { 1, 2, 3 };
unsigned long index;
for (index = 0; index < 3; ++index) {
long x = array[index];
puts(x);
};
}"

  def setup
  end

  def test_empty
    thing = RubyToC.new(Something, :empty)
    assert_equal(@@empty,
		 thing.translate,
		 "Must return an empty method body")
  end

  def test_simple
    thing = RubyToC.new(Something, :simple)
    assert_equal(@@simple,
		 thing.translate,
		 "Must return a basic method body")
  end

  def test_conditional
    thing = RubyToC.new(Something, :conditional)
    assert_equal(@@conditional,
		 thing.translate,
		 "Must return a conditional")
  end

  def test_iteration1
    thing = RubyToC.new(Something, :iteration1)
    assert_equal(@@iteration1,
		 thing.translate,
		 "Must return an iteration")
  end

  def test_iteration2
    thing = RubyToC.new(Something, :iteration2)
    assert_equal(@@iteration2,
		 thing.translate,
		 "Must return an iteration")
  end

  def test_class
    assert_equal([@@conditional, @@empty, @@iteration1, @@iteration2, @@simple].join("\n\n"),
		 RubyToC.translate_all_of(Something),
		 "Must return a lot of shit")
  end

end
