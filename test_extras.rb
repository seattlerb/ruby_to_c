#!/usr/local/bin/ruby -w

require 'type_checker'
require 'test/unit'

class RandomCode # ZenTest SKIP
  def generic_method(x, y)
    specific_method(x, y)
  end

  def specific_method(x, y)
    c = x = y = 0 # make x and y to be longs
    return c.to_i > 0
  end

  def meth_a(x)
    meth_b(x)
  end

  def meth_b(x)
    # nothing to do so we don't hint what x is
  end

end

class TestExtraTypeChecker < Test::Unit::TestCase # ZenTest SKIP

  def setup
    @parser = ParseTree.new
    @rewriter = Rewriter.new
    @type_checker = TypeChecker.new
  end

  # HACK: this shouldn't be in test code. use augment or something
  def process(klass, meth = nil)
    sexp = @parser.parse_tree klass, meth
    sexp = [sexp] unless meth.nil?
    result = []
    sexp.each do | sub_exp|
      result << @type_checker.process(@rewriter.process(sub_exp))
    end
    return result
  end

  def test_type_inference_across_args_known
    generic  = process(RandomCode, :generic_method).first
    specific = process(RandomCode, :specific_method).first

    args_g = generic[2] # FIX FUCK this is horrid
    args_s = specific[2] # FIX FUCK this is horrid

    assert_equal(args_s[1].sexp_type.list_type.object_id, # FIX demeter
                 args_s[2].sexp_type.list_type.object_id,
                 "#specific_method's arguments are unified")

    assert_equal(Type.long, args_s[1].sexp_type,
                 "#specific_method's x is a Long")
    assert_equal(Type.long, args_s[2].sexp_type,
                 "#specific_method's y is a Long")

    assert_equal(args_g[1].sexp_type.list_type.object_id,
                 args_s[1].sexp_type.list_type.object_id,
                 "#specific_method's x and #generic_method's x are unified")

    assert_equal(args_g[2].sexp_type.list_type.object_id,
                 args_s[2].sexp_type.list_type.object_id,
                 "#specific_method's y and #generic_method's y are unified")

    assert_equal(Type.long, args_g[1].sexp_type,
                 "#generic_method's x is a Long")
    assert_equal(Type.long, args_g[2].sexp_type,
                 "#geniric_method's y is a Long")
  end

  def test_type_inference_across_args_unknown
    meth_a = process(RandomCode, :meth_a).first
    meth_b = process(RandomCode, :meth_b).first

    args_a = meth_a[2][1] # FIX FUCK this is horrid
    args_b = meth_b[2][1] # FIX FUCK this is horrid

    assert_equal(args_a.sexp_type.list_type.object_id,
                 args_b.sexp_type.list_type.object_id,
                 "#meth_a and meth_b arguments are unified")
  end

  def test_process_defn_return_val
    ignore = process(RandomCode, :meth_a)
    result = process(RandomCode, :meth_b).first

    assert_equal("meth_b", result[1])
    # FIX: this is the worst API in my codebase - demeter
    assert_equal(Type.unknown, result.sexp_type.type.contents.return_type)
  end

  def test_wtf?
    assert_nothing_thrown do
      process RandomCode
    end
  end

end

