#!/usr/local/bin/ruby -w

require 'test/unit'
require 'ruby_to_c'
require 'something'

class TestRubyToC < Test::Unit::TestCase

  @@empty = "void\nempty() {\n}"
  # TODO: this test is not good... the args should type-resolve or raise
  # TODO: this test is good, we should know that print takes objects... or something
  @@simple = "void\nsimple(VALUE arg1) {\nprint(arg1);\nputs(4 + 2);\n}"
  @@stupid = "VALUE\nstupid() {\nreturn Qnil;\n}"
  @@global = "void\nglobal() {\nfputs(\"blah\", stderr);\n}"
  @@lasgn_call = "void\nlasgn_call() {\nlong c = 2 + 3;\n}"
  @@conditional1 = "long\nconditional1(long arg1) {\nif (arg1 == 0) {\nreturn 1;\n};\n}"
  @@conditional2 = "long\nconditional2(long arg1) {\nif (arg1 == 0) {\n;\n} else {\nreturn 2;\n};\n}"
  @@conditional3 = "long\nconditional3(long arg1) {\nif (arg1 == 0) {\nreturn 3;\n} else {\nreturn 4;\n};\n}"
  @@conditional4 = "long\nconditional4(long arg1) {\nif (arg1 == 0) {\nreturn 2;\n} else {\nif (arg1 < 0) {\nreturn 3;\n} else {\nreturn 4;\n};\n};\n}"
  @@iteration1 = "void\niteration1() {\nlong_array array;\narray.contents = { 1, 2, 3 };\narray.length = 3;\nunsigned long index_x;\nfor (index_x = 0; index_x < array.length; ++index_x) {\nlong x = array.contents[index_x];\nputs(x);\n};\n}"
  @@iteration2 = "void\niteration2() {\nlong_array array;\narray.contents = { 1, 2, 3 };\narray.length = 3;\nunsigned long index_x;\nfor (index_x = 0; index_x < array.length; ++index_x) {\nlong x = array.contents[index_x];\nputs(x);\n};\n}"
  @@iteration3 = "void\niteration3() {\nlong_array array1;\narray1.contents = { 1, 2, 3 };\narray1.length = 3;\nlong_array array2;\narray2.contents = { 4, 5, 6, 7 };\narray2.length = 4;\nunsigned long index_x;\nfor (index_x = 0; index_x < array1.length; ++index_x) {\nlong x = array1.contents[index_x];\nunsigned long index_y;\nfor (index_y = 0; index_y < array2.length; ++index_y) {\nlong y = array2.contents[index_y];\nputs(x);\nputs(y);\n};\n};\n}"
  @@multi_args = "char *\nmulti_args(long arg1, long arg2) {\nlong arg3 = arg1 * arg2 * 7;\nputs(arg3);\nreturn \"foo\";\n}"
  @@bools = "long\nbools(VALUE arg1) {\nif (NIL_P(arg1)) {\nreturn 0;\n} else {\nreturn 1;\n};\n}"
  @@case_stmt = "char *\ncase_stmt() {\nlong var = 2;\nchar * result = \"\";\nswitch (var) {\ncase 1:\nputs(\"something\");\nresult = \"red\";\nbreak;\ncase 2:\ncase 3:\nresult = \"yellow\";\nbreak;\ncase 4:\nbreak;\ndefault:\nresult = \"green\";\nbreak;\n};\nswitch (result) {\ncase \"red\":\nvar = 1;\nbreak;\ncase \"yellow\":\nvar = 2;\nbreak;\ncase \"green\":\nvar = 3;\nbreak;\n};\nreturn result;\n}"
  @@eric_is_stubborn = "char *\neric_is_stubborn() {\nlong var = 42;\nchar * var2 = sprintf(\"%ld\", var);\nfputs(var2, stderr);\nreturn var2;\n}"

  @@__all = []

  Something.instance_methods(false).sort.each do |meth|
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}; assert_equal @@#{meth}, RubyToC.translate(Something, :#{meth}); end"
    else
      eval "def test_#{meth}; flunk \"You haven't added @@#{meth} yet\"; end"
    end
  end

  def ztest_class
    assert_equal(@@__all.join("\n\n"),
		 RubyToC.translate_all_of(Something))
  end

end
