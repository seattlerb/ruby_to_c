#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'minitest/unit'
require 'function_type'
require 'type'

class TestFunctionType < Minitest::Test
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
          refute_equal fun1, fun2
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

    fun9, funa = funa, fun9 # get rid of unused warnings but keep them rooted

    assert_raises(TypeError) do
      fun7.unify_components fun8
    end
  end

end

