#!/usr/local/bin/ruby -w

require 'test/unit'
require 'ruby_to_c'
require 'something'

class TestRubyToC < Test::Unit::TestCase

  @@empty = "void\nempty() {\n}"
  @@simple = "void\nsimple(long arg1) {\nprint(arg1);\nputs(4 + 2);\n}"
  @@conditional = "long\nconditional(long arg1) {\nif (arg1 == 0) {\nreturn 2;\n} else {\nif (arg1 < 0) {\nreturn 3;\n} else {\nreturn 4;\n};\n};\n}"
  @@iteration1 = "void\niteration1() {\nlong array[] = { 1, 2, 3 };\nunsigned long index_x;\nfor (index_x = 0; index_x < 3; ++index_x) {\nlong x = array[index_x];\nputs(x);\n};\n}"
  @@iteration2 = "void\niteration2() {\nlong array[] = { 1, 2, 3 };\nunsigned long index_x;\nfor (index_x = 0; index_x < 3; ++index_x) {\nlong x = array[index_x];\nputs(x);\n};\n}"
  @@iteration3 = "void\niteration3() {\nlong array1[] = { 1, 2, 3 };\nlong array2[] = { 4, 5, 6, 7 };\nunsigned long index_x;\nfor (index_x = 0; index_x < 3; ++index_x) {\nlong x = array1[index_x];\nunsigned long index_y;\nfor (index_y = 0; index_y < 4; ++index_y) {\nlong y = array2[index_y];\nputs(x);\nputs(y);\n};\n};\n}"

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

  def test_iteration3
    thing = RubyToC.new(Something, :iteration3)
    assert_equal(@@iteration3,
		 thing.translate,
		 "Must return an iteration")
  end

  def test_class
    assert_equal([@@conditional, @@empty, @@iteration1,
		  @@iteration2, @@iteration3, @@simple].join("\n\n"),
		 RubyToC.translate_all_of(Something),
		 "Must return a lot of shit")
  end

end
