#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'minitest/test'
require 'function_type'
require 'type'

class TestFunctionType < Minitest::Test
  def setup
    @function_type = FunctionType.new CType.void, [CType.long, CType.str], CType.value
  end

  def test_formal_types
    assert_equal [CType.long, CType.str], @function_type.formal_types
  end

  def test_formal_types=
    @function_type.formal_types = [CType.str, CType.long]
    assert_equal [CType.str, CType.long], @function_type.formal_types
  end

  def test_receiver_type
    assert_equal CType.void, @function_type.receiver_type
  end

  def test_receiver_type=
    @function_type.receiver_type = CType.str
    assert_equal CType.str, @function_type.receiver_type
  end

  def test_return_type
    assert_equal CType.value, @function_type.return_type
  end

  def test_return_type=
    @function_type.return_type = CType.long
    assert_equal CType.long, @function_type.return_type
  end

  def test_equals
    funs = []
    funs << FunctionType.new(CType.unknown, [], CType.unknown)
    funs << FunctionType.new(CType.unknown, [CType.unknown], CType.unknown)
    funs << FunctionType.new(CType.unknown, [], CType.long)
    funs << FunctionType.new(CType.unknown, [CType.long], CType.unknown)
    funs << FunctionType.new(CType.unknown, [CType.long], CType.long)
    funs << FunctionType.new(CType.unknown, [CType.unknown, CType.unknown], CType.unknown)
    funs << FunctionType.new(CType.unknown, [CType.long, CType.unknown], CType.unknown)
    funs << FunctionType.new(CType.unknown, [CType.long, CType.long], CType.long)
    #funs << FunctionType.new(CType.unknown, [], CType.long)

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
    fun1 = FunctionType.new(CType.unknown, [CType.unknown], CType.unknown)
    fun2 = FunctionType.new(CType.long, [CType.long], CType.long)
    fun1.unify_components fun2
    assert_equal fun2, fun1

    fun3 = FunctionType.new(CType.unknown, [CType.long], CType.unknown)
    fun4 = FunctionType.new(CType.long, [CType.unknown], CType.long)
    fun3.unify_components fun4
    assert_equal fun4, fun3

    fun5 = FunctionType.new(CType.unknown, [], CType.unknown)
    fun6 = FunctionType.new(CType.long, [], CType.long)
    fun5.unify_components fun6
    assert_equal fun6, fun5
  end

  def test_initialize_fail
    assert_raises(RuntimeError) do
      FunctionType.new(CType.unknown, nil, CType.long)
    end

    assert_raises(RuntimeError)do
      FunctionType.new(CType.unknown, [], nil)
    end
  end

  def test_unify_components_fail
    fun1 = FunctionType.new(CType.long, [CType.str], CType.unknown)
    fun2 = FunctionType.new(CType.unknown, [CType.long], CType.long)
    assert_raises(TypeError) do
      fun1.unify_components fun2
    end

    fun3 = FunctionType.new(CType.long, [], CType.unknown)
    fun4 = FunctionType.new(CType.unknown, [CType.unknown], CType.long)
    assert_raises(TypeError) do
      fun3.unify_components fun4
    end

    fun5 = FunctionType.new(CType.long, [CType.unknown], CType.unknown)
    fun6 = FunctionType.new(CType.unknown, [], CType.long)
    assert_raises(TypeError) do
      fun5.unify_components fun6
    end

    fun7 = FunctionType.new(CType.long, [], CType.str)
    fun8 = FunctionType.new(CType.unknown, [], CType.long)
    assert_raises(TypeError) do
      fun7.unify_components fun8
    end

    fun9 = FunctionType.new(CType.long, [], CType.str)
    funa = FunctionType.new(CType.str, [], CType.unknown)

    fun9, funa = funa, fun9 # get rid of unused warnings but keep them rooted

    assert_raises(TypeError) do
      fun7.unify_components fun8
    end
  end

end
