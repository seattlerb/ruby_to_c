#!/usr/local/bin/ruby -w

require 'infer_types'
require 'test/unit'

class RandomCode
  def generic_method(x, y)
    specific_method(x, y)
  end

  def specific_method(x, y)
    c = x <=> y # force x & y into long
    c.to_i > 0
  end

  def meth_a(x)
    meth_b(x)
  end

  def meth_b(x)
    # nothing to do so we don't hint what x is
  end

end

class TestExtraInferTypes < Test::Unit::TestCase

  def test_type_inference_across_args_known
    inferer  = InferTypes.new
    inferer.augment(RandomCode, :generic_method)
    inferer.augment(RandomCode, :specific_method)

    tree = inferer.tree.tree # HACK augment doesn't return the processed method

    generic = tree[0]
    specific = tree[1]
    
    args_g = generic[2][1][1] # FIX FUCK this is horrid
    args_s = specific[2][1][1] # FIX FUCK this is horrid

    assert_equal(args_g[1].object_id, args_s[1].object_id)
    assert_equal(args_g[2].object_id, args_s[2].object_id)
    assert_equal(Type.long, args_s[1].last)
    assert_equal(Type.long, args_s[2].last)
    assert_equal(Type.long, args_g[1].last)
    assert_equal(Type.long, args_g[2].last)
  end

  def test_type_inference_across_args_unknown
    inferer  = InferTypes.new
    inferer.augment(RandomCode, :meth_a)
    inferer.augment(RandomCode, :meth_b)

    tree = inferer.tree.tree # HACK augment doesn't return the processed method

    meth_a = tree[0]
    meth_b = tree[1]

    args_a = meth_a[2][1][1] # FIX FUCK this is horrid
    args_b = meth_b[2][1][1] # FIX FUCK this is horrid

    assert_equal(args_a.object_id, args_b.object_id)
  end

  def test_augment_return_val
    inferer  = InferTypes.new
    inferer.augment(RandomCode, :meth_a)
    result = inferer.augment(RandomCode, :meth_b)

    p result

    assert_equal("meth_b", result[1])
  end

  def xtest_wtf?
    assert_nothing_thrown do
      InferTypes.new.augment(RandomCode)
    end
  end

end

