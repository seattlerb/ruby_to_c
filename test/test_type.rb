#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'minitest/unit'
require 'type'
require 'sexp_processor' # for deep clone FIX ?

class TestType < Minitest::Test
  def setup
    @unknown = Type.unknown
    @unknown_list = Type.unknown_list
    @long = Type.long
    @long_list = Type.new(:long, true)
  end

  def test_function?
    assert ! @long.function?
    assert ! @long_list.function?
    assert ! @unknown.function?
    assert ! @unknown_list.function?
    assert Type.function(Type.str, [Type.str], Type.str).function?
  end

  def test_list
    assert_equal false, @long.list
    assert_equal true, @long_list.list
  end

  def test_list=
    long = Type.long.deep_clone
    long_list = Type.long_list.deep_clone

    long.list = true
    long_list.list = false

    assert_equal true, long.list
    assert_equal false, long_list.list
  end

  def test_type
    assert_kind_of Handle, @long.type
    assert_equal :long, @long.type.contents
  end

  def test_type_good
    file = Type.file
    assert_kind_of Type, file
    assert_equal :file, file.type.contents
  end

  def test_type_bad
    assert_raises(RuntimeError) do
      Type.blahblah
    end
  end

  def test_type=
    long = Type.long.deep_clone
    long.type = "something"
    assert_equal "something", long.type
  end

  def test_unknown_types
    assert_raises(RuntimeError) do
      Type.new(:some_made_up_type)
    end

    assert_raises(RuntimeError) do
      Type.some_made_up_type
    end
  end

  def test_function
    # TODO: actually TEST something here
    Type.function([Type.unknown], Type.unknown)
  end

  def test_list_type
    assert_equal :long, @long_list.list_type
  end

  def test_equals
    type = Type.long
    refute_equal @unknown, type
    assert_equal @long, type
    refute_equal @long_list, type
  end

  def test_hash
    long1 = Type.long
    long2 = Type.long

    a = Type.unknown
    a.unify long1

    b = Type.unknown
    b.unify long2

    assert a == b, "=="
    assert a === b, "==="
    assert a.eql?(b), ".eql?"
    assert_equal a.hash, b.hash, "hash"

    assert_equal 1, [a, b].uniq.size
  end

  def test_list_equal
    type = Type.new(:long, true)
    refute_equal @unknown, type
    refute_equal @long, type
    assert_equal @long_list, type
  end

  def test_to_s
    assert_equal "Type.long", @long.to_s
    assert_equal "Type.long_list", @long_list.to_s
  end

  def test_unknown?
    assert_equal Type.unknown, Type.unknown
    refute_same Type.unknown, Type.unknown
  end

  def test_unknown_list
    assert_equal @unknown_list, Type.unknown_list
    refute_same Type.unknown_list, Type.unknown_list
    assert @unknown_list.list?
  end

  def test_unify_fail
    long = Type.new(:long)
    string = Type.new(:str)
    long_list = Type.new(:long, true)

    assert_raises(TypeError) do
      long.unify string
    end

    assert_raises(TypeError) do
      long.unify long_list
    end
  end

  def test_unify_simple
    long = Type.new(:long)
    unknown = Type.unknown

    assert_equal @long, long

    unknown.unify long

    assert !unknown.list?
    assert_equal long, unknown
    assert_equal @long, unknown
  end

  def test_unify_list
    long_list = Type.new(:long, true)
    unknown = Type.unknown

    assert_equal @long_list, long_list

    unknown.unify long_list

    assert unknown.list?
    assert_equal long_list, unknown
    assert_equal @long_list, unknown
  end

  def test_unify_link
    unknown1 = Type.unknown
    unknown2 = Type.unknown
    long = Type.new(:long)

    unknown1.unify unknown2
    assert_same(unknown1.type, unknown2.type,
                "Type of unified unknowns must be identical")

    long.unify unknown2
    assert_equal(long, unknown2)
    assert_equal(long, unknown1,
                 "Type unified across all linked Types")
  end

  def test_unify_function
    fun = Type.function [Type.unknown], Type.unknown
    @unknown.unify fun
    assert_equal fun, @unknown
  end

end
