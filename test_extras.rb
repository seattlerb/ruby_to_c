#!/usr/local/bin/ruby -w

require 'infer_types'
require 'test/unit'

class RandomCode
  def generic_method(x, y)
    return false if specific_method(x, y)
    return true
  end

  def specific_method(x, y)
    c = x <=> y
    return c.to_i > 0
  end
end

class TestExtraInferTypes < Test::Unit::TestCase

  def test_blah
    inferer  = InferTypes.new
    generic  = inferer.augment(RandomCode, :generic_method)
    specific = inferer.augment(RandomCode, :specific_method)

    args = generic[2][1][1] # FIX FUCK this is horrid

    assert_equal(Type.long, args[1].last)
    assert_equal(Type.long, args[2].last)
  end

  def test_wtf?
    assert_nothing_thrown do
      InferTypes.new.augment(RandomCode)
    end
  end

end

