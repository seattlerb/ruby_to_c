#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'
require 'type_checker'

class TestHandle < Test::Unit::TestCase

  def setup
    @handle = Handle.new("text")
  end

  def test_contents
    assert_equal "text", @handle.contents
  end

  def test_contents=
    @handle.contents = "new text"
    assert_equal "new text", @handle.contents
  end

  def test_equals
    obj = "foo"
    handle1 = Handle.new obj
    handle2 = Handle.new obj
    assert_equal handle1, handle2
  end

  def test_equals_reassign
    obj = "foo"
    handle2 = Handle.new obj
    @handle.contents = obj
    assert_equal @handle, handle2
  end

end

class TestFunctionType < Test::Unit::TestCase

  def setup
    @function_type = FunctionType.new Type.void, [Type.long, Type.str], Type.value
  end

  def test_formal_types
    assert_equal [Type.long, Type.str], @function_type.formal_types
  end

  def test_formal_types=
    @function_type.formal_types = [Type.str, Type.long]
    assert_equal [Type.str, Type.long], @function_type.formal_types
  end

  def test_receiver_type
    assert_equal Type.void, @function_type.receiver_type
  end

  def test_receiver_type=
    @function_type.receiver_type = Type.str
    assert_equal Type.str, @function_type.receiver_type
  end

  def test_return_type
    assert_equal Type.value, @function_type.return_type
  end

  def test_return_type=
    @function_type.return_type = Type.long
    assert_equal Type.long, @function_type.return_type
  end

  def test_equals
    funs = []
    funs << FunctionType.new(Type.unknown, [], Type.unknown)
    funs << FunctionType.new(Type.unknown, [Type.unknown], Type.unknown)
    funs << FunctionType.new(Type.unknown, [], Type.long)
    funs << FunctionType.new(Type.unknown, [Type.long], Type.unknown)
    funs << FunctionType.new(Type.unknown, [Type.long], Type.long)
    funs << FunctionType.new(Type.unknown, [Type.unknown, Type.unknown], Type.unknown)
    funs << FunctionType.new(Type.unknown, [Type.long, Type.unknown], Type.unknown)
    funs << FunctionType.new(Type.unknown, [Type.long, Type.long], Type.long)
    #funs << FunctionType.new(Type.unknown, [], Type.long)

    funs.each_with_index do |fun1, i|
      funs.each_with_index do |fun2, j|
        if i == j then
          assert_equal fun1, fun2
        else
          assert_not_equal fun1, fun2
        end
      end
    end
  end

  def test_unify_components
    fun1 = FunctionType.new(Type.unknown, [Type.unknown], Type.unknown)
    fun2 = FunctionType.new(Type.long, [Type.long], Type.long)
    fun1.unify_components fun2
    assert_equal fun2, fun1

    fun3 = FunctionType.new(Type.unknown, [Type.long], Type.unknown)
    fun4 = FunctionType.new(Type.long, [Type.unknown], Type.long)
    fun3.unify_components fun4
    assert_equal fun4, fun3

    fun5 = FunctionType.new(Type.unknown, [], Type.unknown)
    fun6 = FunctionType.new(Type.long, [], Type.long)
    fun5.unify_components fun6
    assert_equal fun6, fun5
  end

  def test_initialize_fail
    assert_raises(RuntimeError) do
      FunctionType.new(Type.unknown, nil, Type.long)
    end

    assert_raises(RuntimeError)do
      FunctionType.new(Type.unknown, [], nil)
    end
  end

  def test_unify_components_fail
    fun1 = FunctionType.new(Type.long, [Type.str], Type.unknown)
    fun2 = FunctionType.new(Type.unknown, [Type.long], Type.long)
    assert_raises(TypeError) do
      fun1.unify_components fun2
    end

    fun3 = FunctionType.new(Type.long, [], Type.unknown)
    fun4 = FunctionType.new(Type.unknown, [Type.unknown], Type.long)
    assert_raises(TypeError) do
      fun3.unify_components fun4
    end

    fun5 = FunctionType.new(Type.long, [Type.unknown], Type.unknown)
    fun6 = FunctionType.new(Type.unknown, [], Type.long)
    assert_raises(TypeError) do
      fun5.unify_components fun6
    end

    fun7 = FunctionType.new(Type.long, [], Type.str)
    fun8 = FunctionType.new(Type.unknown, [], Type.long)
    assert_raises(TypeError) do
      fun7.unify_components fun8
    end

    fun9 = FunctionType.new(Type.long, [], Type.str)
    funa = FunctionType.new(Type.str, [], Type.unknown)
    assert_raises(TypeError) do
      fun7.unify_components fun8
    end
  end

end

class TestType < Test::Unit::TestCase

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
    assert_nothing_raised do
      Type.function([Type.unknown], Type.unknown)
    end
  end

  def test_list_type
    assert_equal :long, @long_list.list_type
  end

  def test_equals
    type = Type.long
    assert_not_equal @unknown, type
    assert_equal @long, type
    assert_not_equal @long_list, type
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
    assert_not_equal @unknown, type
    assert_not_equal @long, type
    assert_equal @long_list, type
  end

  def test_to_s
    assert_equal "Type.long", @long.to_s
    assert_equal "Type.long_list", @long_list.to_s
  end

  def test_unknown?
    assert_equal Type.unknown, Type.unknown
    assert_not_same Type.unknown, Type.unknown
  end

  def test_unknown_list
    assert_equal @unknown_list, Type.unknown_list
    assert_not_same Type.unknown_list, Type.unknown_list
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

class TestEnvironment < Test::Unit::TestCase

  def setup
    @env = Environment.new
  end

  def test_add
    @env.add 'var', 42
    assert_equal 42, @env.lookup('var')
  end

  def test_add_segmented
    @env.scope do
      @env.add 'var', 42
      assert_equal 42, @env.lookup('var')
    end

    assert_raises RuntimeError do
      @env.lookup('var')
    end
  end

  def test_current
    @env.add 'var', 42
    
    expected = { 'var' => 42 }
    assert_equal expected, @env.current
  end

  def test_depth
    assert_equal 1, @env.depth

    @env.scope do
      assert_equal 2, @env.depth
    end

    assert_equal 1, @env.depth
  end

  def test_env
    assert_equal [{}], @env.env
  end

  def test_env=
    @env.env = "something"
    assert_equal "something", @env.env
  end

  def test_extend
    assert_equal [{}], @env.env

    @env.extend
    assert_equal [{}, {}], @env.env
  end

  def test_lookup
    @env.add 'var', 1
    assert_equal 1, @env.lookup('var')
  end

  def test_lookup_raises
    assert_raises RuntimeError do
      @env.lookup('var')
    end
  end

  def test_lookup_extended
    @env.add 'var', 1
    assert_equal 1, @env.lookup('var')

    @env.scope do
      assert_equal 1, @env.lookup('var')
    end
  end

  def test_scope
    @env.add 'var', 1
    assert_equal 1, @env.lookup('var')

    @env.scope do
      @env.add 'var', 2
      assert_equal 2, @env.lookup('var')
    end

    assert_equal 1, @env.lookup('var')
  end

  def test_unextend
    @env.extend

    @env.add 'var', 1

    assert_equal 1, @env.lookup('var')

    @env.unextend

    assert_raises RuntimeError do
      @env.lookup 'var'
    end
  end

end

class TestFunctionTable < Test::Unit::TestCase

  def setup
    @function_table = FunctionTable.new
  end

  def test_add_function
    type = @function_table.add_function 'func', Type.long

    assert_equal Type.long, type
    assert_equal Type.long, @function_table['func']
  end

  def test_cheat
    @function_table.add_function 'func', Type.long
    @function_table.add_function 'func', Type.str

    assert_equal [Type.long, Type.str], @function_table.cheat('func')
  end

  def test_has_key?
    @function_table.add_function 'func', Type.long

    assert_equal true, @function_table.has_key?('func')
    assert_equal false, @function_table.has_key?('no such func')
  end

  def test_index
    @function_table.add_function 'func', Type.long

    assert_equal Type.long, @function_table['func']

    @function_table.add_function 'func', Type.str

    assert_equal Type.long, @function_table['func']
  end

  def test_unify_one_type
    @function_table.add_function 'func', Type.unknown

    @function_table.unify 'func', Type.long do
      flunk "Block should not have been called"
    end

    assert_equal Type.long, @function_table['func']
  end

  def test_unify_two_type
    @function_table.add_function 'func', Type.unknown
    @function_table.add_function 'func', Type.str

    @function_table.unify 'func', Type.long do
      flunk "Block should not have been called"
    end

    assert_equal Type.long, @function_table['func']
  end

  def test_unify_block_called_no_type
    @function_table.add_function 'func', Type.str

    test_var = false

    @function_table.unify 'func', Type.long do
      test_var = true
    end

    assert test_var, "Block not called"
  end

  def test_unify_block_called_no_unify
    test_var = false

    @function_table.unify 'func', Type.long do
      test_var = true
    end

    assert test_var, "Block not called"
  end

end

