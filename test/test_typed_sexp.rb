#!/usr/local/bin/ruby -w

require 'minitest/autorun' if $0 == __FILE__
require 'test_sexp' # from sexp_processor for TestSexp
require 'typed_sexp'

class TestTypedSexp < TestSexp
  def setup
    super
    @sexp.c_type = CType.str
  end

  def test__set_c_type
    assert_equal CType.str, @sexp.c_type
    @sexp._set_c_type CType.bool
    assert_equal CType.bool, @sexp.c_type
  end

  def test_equals2_tsexp
    sexp2 = s(1, 2, 3)
    sexp3 = t(1, 2, 3, CType.str)
    assert_equal(@sexp, sexp3)
    refute_equal(@sexp, sexp2)
  end

  def test_equals_array_typed
    # can't use assert_equals because it uses array as receiver
    refute_equal(@sexp, [1, 2, 3, CType.str],
                 "Sexp must not be equal to equivalent array")
    # both directions just in case
    refute_equal([1, 2, 3, CType.str], @sexp,
                 "Sexp must not be equal to equivalent array")
  end

  def test_equals_not_body_typed
    sexp2 = t(1, 2, 5)
    sexp2.c_type = CType.str
    refute_equal(@sexp, sexp2)
  end

  def test_equals_not_type
    sexp2 = t(1, 2, 3)
    sexp2.c_type = CType.long
    refute_equal(@sexp, sexp2)
  end

  def test_equals_sexp
    sexp2 = t(1, 2, 3, CType.str)
    assert_equal(@sexp, sexp2)
  end

  def test_equals_c_typed
    sexp2 = t(1, 2, 3)
    sexp2.c_type = CType.str
    assert_equal(@sexp, sexp2)
  end

  def test_new_nested_typed
    @sexp = TypedSexp.new(:lasgn, "var", TypedSexp.new(:str, "foo", CType.str), CType.str)
    assert_equal('t(:lasgn, "var", t(:str, "foo", Type.str), Type.str)',
                 @sexp.inspect)
  end

  def test_pretty_print_typed
    assert_pretty_print("t(Type.str)",
                        t(CType.str))
    assert_pretty_print("t(:a, Type.long)",
                        t(:a, CType.long))
    assert_pretty_print("t(:a, :b, Type.long)",
                        t(:a, :b, CType.long))
    assert_pretty_print("t(:a, t(:b, Type.long), Type.str)",
                        t(:a, t(:b, CType.long), CType.str))
  end

  def test_c_type
    assert_equal(CType.str, @sexp.c_type)
  end

  def test_c_type=
    assert_equal(CType.str, @sexp.c_type)
    # FIX: we can't set c_type a second time, please expand tests
    @sexp._set_c_type 24
    assert_equal(24, @sexp.c_type)
  end

  def test_c_type_array_hetero
    @sexp = t(:array, t(:lit, 1, CType.long),
                          t(:str, "foo", CType.str))
    assert_equal(CType.hetero, @sexp.c_type)
    assert_equal([CType.long, CType.str], @sexp.c_types)
  end

  def test_c_type_array_homo
    @sexp = t(:array, t(:lit, 1, CType.long),
                          t(:lit, 2, CType.long))
    assert_equal(CType.homo, @sexp.c_type)
    assert_equal([CType.long, CType.long], @sexp.c_types)
  end

  def test_c_type_array_nested
    @sexp = t(:array, t(:lit, 1, CType.long),
                     t(:array, t(:lit, 1, CType.long)))
    assert_equal(CType.hetero, @sexp.c_type)
    assert_equal([CType.long, CType.homo], @sexp.c_types)
  end

  def test_c_types
    assert_raises(RuntimeError) do
      @sexp.c_types
    end

    @sexp = t(:array, t(:lit, 1, CType.long), t(:str, "blah", CType.str))

    assert_equal([CType.long, CType.str], @sexp.c_types)
  end

  def test_sexp_body # override from TestSexp
    assert_equal t(2, 3, CType.str), @sexp.sexp_body
    assert_equal s(),     s(:x).sexp_body
    assert_equal s(),     s().sexp_body

    assert_instance_of Sexp, s().sexp_body
  end

  def test_to_a
    @sexp = t(1, 2, 3)
    assert_equal([1, 2, 3], @sexp.to_a)
  end

  def test_to_a_typed
    assert_equal([1, 2, 3, CType.str], @sexp.to_a)
  end

  def test_to_s_typed
    k = @sexp_class
    n = k.name[0].chr.downcase
    assert_equal("#{n}(Type.long)",
                 k.new(CType.long).inspect)
    assert_equal("#{n}(:a, Type.long)",
                 k.new(:a, CType.long).inspect)
    assert_equal("#{n}(:a, :b, Type.long)",
                 k.new(:a, :b, CType.long).inspect)
    assert_equal("#{n}(:a, #{n}(:b, Type.long), Type.str)",
                 k.new(:a, k.new(:b, CType.long), CType.str).inspect)
  end
end
