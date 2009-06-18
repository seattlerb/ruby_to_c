#!/usr/local/bin/ruby -w

require 'minitest/autorun' if $0 == __FILE__
require 'test_sexp'
require 'typed_sexp'

class TestTypedSexp < TestSexp
  def setup
    super
    @sexp.sexp_type = Type.str
  end

  def test__set_sexp_type
    assert_equal Type.str, @sexp.sexp_type
    @sexp._set_sexp_type Type.bool
    assert_equal Type.bool, @sexp.sexp_type
  end

  def test_equals2_tsexp
    sexp2 = s(1, 2, 3)
    sexp3 = t(1, 2, 3, Type.str)
    assert_equal(@sexp, sexp3)
    refute_equal(@sexp, sexp2)
  end

  def test_equals_array_typed
    # can't use assert_equals because it uses array as receiver
    refute_equal(@sexp, [1, 2, 3, Type.str],
                 "Sexp must not be equal to equivalent array")
    # both directions just in case
    refute_equal([1, 2, 3, Type.str], @sexp,
                 "Sexp must not be equal to equivalent array")
  end

  def test_equals_not_body_typed
    sexp2 = t(1, 2, 5)
    sexp2.sexp_type = Type.str
    refute_equal(@sexp, sexp2)
  end

  def test_equals_not_type
    sexp2 = t(1, 2, 3)
    sexp2.sexp_type = Type.long
    refute_equal(@sexp, sexp2)
  end

  def test_equals_sexp
    sexp2 = t(1, 2, 3, Type.str)
    assert_equal(@sexp, sexp2)
  end

  def test_equals_sexp_typed
    sexp2 = t(1, 2, 3)
    sexp2.sexp_type = Type.str
    assert_equal(@sexp, sexp2)
  end

  def test_new_nested_typed
    @sexp = TypedSexp.new(:lasgn, "var", TypedSexp.new(:str, "foo", Type.str), Type.str)
    assert_equal('t(:lasgn, "var", t(:str, "foo", Type.str), Type.str)',
                 @sexp.inspect)
  end

  def test_pretty_print_typed
    util_pretty_print("t(Type.str)",
                      t(Type.str))
    util_pretty_print("t(:a, Type.long)",
                      t(:a, Type.long))
    util_pretty_print("t(:a, :b, Type.long)",
                      t(:a, :b, Type.long))
    util_pretty_print("t(:a, t(:b, Type.long), Type.str)",
                      t(:a, t(:b, Type.long), Type.str))
  end

  def test_sexp_type
    assert_equal(Type.str, @sexp.sexp_type)
  end

  def test_sexp_type=
    assert_equal(Type.str, @sexp.sexp_type)
    # FIX: we can't set sexp_type a second time, please expand tests
    @sexp._set_sexp_type 24
    assert_equal(24, @sexp.sexp_type)
  end

  def test_sexp_type_array_hetero
    @sexp = t(:array, t(:lit, 1, Type.long),
                          t(:str, "foo", Type.str))
    assert_equal(Type.hetero, @sexp.sexp_type)
    assert_equal([Type.long, Type.str], @sexp.sexp_types)
  end

  def test_sexp_type_array_homo
    @sexp = t(:array, t(:lit, 1, Type.long),
                          t(:lit, 2, Type.long))
    assert_equal(Type.homo, @sexp.sexp_type)
    assert_equal([Type.long, Type.long], @sexp.sexp_types)
  end

  def test_sexp_type_array_nested
    @sexp = t(:array, t(:lit, 1, Type.long),
                     t(:array, t(:lit, 1, Type.long)))
    assert_equal(Type.hetero, @sexp.sexp_type)
    assert_equal([Type.long, Type.homo], @sexp.sexp_types)
  end

  def test_sexp_types
    assert_raises(RuntimeError) do
      @sexp.sexp_types
    end

    @sexp = t(:array, t(:lit, 1, Type.long), t(:str, "blah", Type.str))

    assert_equal([Type.long, Type.str], @sexp.sexp_types)
  end

  def test_to_a
    @sexp = t(1, 2, 3)
    assert_equal([1, 2, 3], @sexp.to_a)
  end

  def test_to_a_typed
    assert_equal([1, 2, 3, Type.str], @sexp.to_a)
  end

  def test_to_s_typed
    k = @sexp_class
    n = k.name[0].chr.downcase
    assert_equal("#{n}(Type.long)",
                 k.new(Type.long).inspect)
    assert_equal("#{n}(:a, Type.long)",
                 k.new(:a, Type.long).inspect)
    assert_equal("#{n}(:a, :b, Type.long)",
                 k.new(:a, :b, Type.long).inspect)
    assert_equal("#{n}(:a, #{n}(:b, Type.long), Type.str)",
                 k.new(:a, k.new(:b, Type.long), Type.str).inspect)
  end
end
