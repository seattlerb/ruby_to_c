#!/usr/local/bin/ruby -w

$TESTING = true

require 'type_checker'
require 'test/unit' if $0 == __FILE__
require 'test/unit/testcase'

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

class TestExtraTypeChecker < Test::Unit::TestCase # ZenTest SKIP

  def setup
    @parser = ParseTree.new
    @rewriter = Rewriter.new
    @type_checker = TypeChecker.new
  end

  # HACK: this shouldn't be in test code. use augment or something
#   def test_process_defn_return_val
#     ignore = util_process(RandomCode, :meth_a)
#     result = util_process(RandomCode, :meth_b).first

#     assert_equal(:meth_b, result[1])
#     # FIX: this is the worst API in my codebase - demeter
#     assert_equal(Type.void, result.sexp_type.list_type.return_type)
#   end

#   def test_type_inference_across_args_known
#     generic  = util_process(RandomCode, :generic_method).first
#     # puts
#     # pp @type_checker.functions
#     specific = util_process(RandomCode, :specific_method).first
#     # puts
#     # pp @type_checker.functions

#     # pp generic
#     # pp specific

#     args_g = generic[2]  # FIX FUCK this is horrid
#     args_s = specific[2] # FIX FUCK this is horrid

#     #assert_equal(args_s[1].sexp_type.list_type.object_id, # FIX demeter
#     #             args_s[2].sexp_type.list_type.object_id,
#     #             "#specific_method's arguments are unified")

#     assert_equal(Type.long, args_s[1].sexp_type,
#                  "#specific_method's x is a Long")
#     assert_equal(Type.long, args_g[1].sexp_type, # FAILS
#                  "#generic_method's x is a Long")

#     assert_equal(args_g[1].sexp_type.list_type.object_id,
#                  args_s[1].sexp_type.list_type.object_id,
#                  "#specific_method's x and #generic_method's x are unified")

#     #     assert_equal(args_g[2].sexp_type.list_type.object_id,
#     #                  args_s[2].sexp_type.list_type.object_id,
#     #                 "#specific_method's y and #generic_method's y are unified")

#     #     assert_equal(Type.long, args_s[2].sexp_type,
#     #                  "#specific_method's y is a Long")
#     #     assert_equal(Type.long, args_g[2].sexp_type,
#     #                  "#generic_method's y is a Long")
#   end

#   def test_type_inference_across_args_unknown
#     meth_a = util_process(RandomCode, :meth_a).first
#     meth_b = util_process(RandomCode, :meth_b).first

#     args_a = meth_a[2][1] # FIX FUCK this is horrid
#     args_b = meth_b[2][1] # FIX FUCK this is horrid

#     assert_equal(args_a.sexp_type.list_type,
#                  args_b.sexp_type.list_type,
#                  "#meth_a and meth_b arguments are the same after unification")

#     assert_equal(args_a.sexp_type.list_type.object_id,
#                  args_b.sexp_type.list_type.object_id,
#                  "#meth_a and meth_b arguments are unified by object_id")
#   end

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

  def util_process(klass, meth)
    sexp = @parser.parse_tree_for_method klass, meth
    sexp = [sexp] unless meth.nil?
    result = []
    sexp.each do | sub_exp|
      result << @type_checker.process(@rewriter.process(sub_exp))
    end
    return result
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
