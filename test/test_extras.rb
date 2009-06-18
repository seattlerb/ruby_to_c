#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'minitest/unit'
require 'type_checker'

class RandomCode # ZenTest SKIP
  def specific_method(x)
    x = 0 # make x and y to be longs
    return c.to_i > 0
  end

  def generic_method(x)
    specific_method(x)
  end

  def meth_b(x)
    # nothing to do so we don't hint what x is
  end

  def meth_a(x)
    meth_b(x)
  end

end

class TestExtraTypeChecker < MiniTest::Unit::TestCase # ZenTest SKIP

  def setup
    @rewriter = Rewriter.new
    @type_checker = TypeChecker.new
  end

  def test_unify_function_args
    act, bct = util_unify_function.map { |x| x.formal_types }
    assert_equal act.first.list_type, bct.first.list_type
    assert_equal act.first.list_type.object_id, bct.first.list_type.object_id
  end

  def test_unify_function_receiver
    act, bct = util_unify_function
    assert_equal act.receiver_type.list_type, bct.receiver_type.list_type
    assert_equal act.receiver_type.list_type.object_id, bct.receiver_type.list_type.object_id
    assert_equal act, bct
  end

  def test_unify_function_return
    act, bct = util_unify_function
    assert_equal act.return_type.list_type, bct.return_type.list_type
    assert_equal act.return_type.list_type.object_id, bct.return_type.list_type.object_id
  end

  def test_unify_function_whole
    act, bct = util_unify_function
    assert_equal act, bct
  end

  def util_unify_function
    a = Type.function(Type.unknown, [ Type.unknown ], Type.unknown)
    b = Type.function(Type.long, [ Type.str ], Type.void)
    a.unify b
    act = a.list_type
    bct = b.list_type
    return act, bct
  end
end
