#!/usr/local/bin/ruby -w

require 'test/unit'
require 'ruby_to_c'
require 'something'

class TestRubyToC < Test::Unit::TestCase

  def setup
    @thing = RubyToC.new
  end

  def test_empty
    assert_equal("void\nempty() {\n}",
		 @thing.translate(Something, :empty),
		 "Must return an empty method body")
  end

  def ztest_simple
    assert_equal(,
		 @thing.translate(Something, :simple),
		 "Must return a basic method body")
  end

  def ztest_conditional
    assert_equal(@@conditional,
		 @thing.translate(Something, :conditional),
		 "Must return a conditional")
  end

  def ztest_iteration1
    assert_equal(@@iteration1,
		 @thing.translate(Something, :iteration1),
		 "Must return an iteration")
  end

  def ztest_iteration2
    assert_equal(@@iteration2,
		 @thing.translate(Something, :iteration2),
		 "Must return an iteration")
  end

  def ztest_class
    assert_equal([@@conditional, @@empty, @@iteration1, @@iteration2, @@simple],
		 @thing.translate(Something),
		 "Must return a lot of shit")
  end

end
