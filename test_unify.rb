#!/usr/local/bin/ruby -w

require 'test/unit'
require 'infer_types'

class TestHandle < Test::Unit::TestCase

  def setup
    @handle = Handle.new("text")
  end

  def test_contents
    assert_equal "text", @handle.contents
  end

  def test_set_contents
    @handle.contents = "new text"
    assert_equal "new text", @handle.contents
  end

  def test_handle
    obj = "foo"
    handle1 = Handle.new obj
    handle2 = Handle.new obj
    assert_equal handle1, handle2
  end

  def test_handle2
    obj = "foo"
    handle2 = Handle.new obj
    @handle.contents = obj
    assert_equal @handle, handle2
  end

end

class TestType < Test::Unit::TestCase

  def setup
    @unknown = Type.make_unknown
    @unknown_list = Type.make_unknown_list
    @long = Type.new :long
    @long_list = Type.new :long, true
  end

  def test_unknown_types
    assert_raises(RuntimeError) do
      Type.new :some_made_up_type
    end
  end

  def test_default_unknown
    type = Type.new
    assert_equal @unknown, type
  end

  def test_list_type
    assert_equal :long, @long_list.list_type
  end

  def test_equal
    type = Type.new :long
    assert_not_equal @unknown, type
    assert_equal @long, type
    assert_not_equal @long_list, type
  end

  def test_list_equal
    type = Type.new :long, true
    assert_not_equal @unknown, type
    assert_not_equal @long, type
    assert_equal @long_list, type
  end

  def test_to_s
    assert_equal "Integer", @long.to_s
    assert_equal "Integer list", @long_list.to_s
  end

  def test_make_unknown
    assert_equal @unknown, Type.make_unknown
  end

  def test_make_unknown_list
    assert_equal @unknown_list, Type.make_unknown_list
    assert @unknown_list.list?
  end

  def test_unify_fail
    long = Type.new(:long)
    string = Type.new(:str)
    long_list = Type.new(:long, true)

    assert_raises(RuntimeError) do
      long.unify string
    end

    assert_raises(RuntimeError) do
      long.unify long_list
    end
  end

  def test_unify_simple
    long = Type.new(:long)
    unknown = Type.make_unknown

    assert_equal @long, long

    unknown.unify long

    assert !unknown.list?
    assert_equal long, unknown
    assert_equal @long, unknown
  end

  def test_unify_list
    long_list = Type.new(:long, true)
    unknown = Type.make_unknown

    assert_equal @long_list, long_list

    unknown.unify long_list

    assert unknown.list?
    assert_equal long_list, unknown
    assert_equal @long_list, unknown
  end

  def test_unify_link
    unknown1 = Type.make_unknown
    unknown2 = Type.make_unknown
    long = Type.new(:long)

    unknown1.unify unknown2
    assert_same(unknown1.type, unknown2.type,
                "Type of unified unknowns must be identical")

    long.unify unknown2
    assert_equal(long, unknown2)
    assert_equal(long, unknown1,
                 "Type unified across all linked Types")
  end

end


