#!/usr/local/bin/ruby -w

require 'test/unit'
require 'infer_types'

class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

class TestUnify < Test::Unit::TestCase

  include Unify

  def test_make_unknown
    assert_equal([:unknown], make_unknown)
  end

  def test_type_of
    assert_equal(:long,
                 type_of(:long))
    assert_equal(:str,
                 type_of(:str))
    assert_equal(:bool,
                 type_of(:bool))
    assert_equal([:unknown],
                 type_of(:unknown))
    assert_equal(:str,
                 type_of([:str]))
    assert_equal(:str,
                 type_of([[[[[:str]]]]]))
    assert_equal([:list, [:long]],
                 type_of([:list, [:long]]))
    assert_equal([:list, [:list, [:long]]],
                 type_of([:list, [:list, [:long]]]))
  end

  def test_end_of
    a = make_unknown
    b = [:list, [:long]]
    c = [:list, [:list, [:long]]]

    assert_same(a, end_of(a))
    assert_same(b[-1], end_of(b))
    assert_same(c[-1][-1], end_of(c))
  end

  def test_unify_atoms
    result = unify(:str, :str)
    assert_equal(:str, result)
    assert_equal(:str, unify(:str, make_unknown))
    assert_equal([:unknown], unify(make_unknown, make_unknown))
    assert_equal(:str, unify(make_unknown, :str))
  end

  def test_unify_lists
    b  = [:list, [:long]]
    b2 = [:list, [:long]]

    assert_equal(b2, unify(b.deep_clone, b.deep_clone))
    assert_equal(b2, unify(b.deep_clone, make_unknown))
    assert_equal(b2, unify(make_unknown, b.deep_clone))
  end

  def test_unify_mismatched_1
    assert_raise(RuntimeError) do
      unify(:str, :long)
    end
  end

  def test_unify_mismatched_2
    assert_raise(RuntimeError) do
      unify(:bool, [:list, [:bool]])
    end
  end

  def test_unify_mismatched_2_switched
    assert_raise(RuntimeError) do
      unify([:list, [:bool]], :bool)
    end
  end

  def test_unify_mismatched_3
    assert_raise(RuntimeError) do
      unify([:list, [:bool]], [:list, [:long]])
    end
  end

end

