#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit' if $0 == __FILE__
require 'test/unit/testcase'
require 'function_table'
require 'type'

class TestFunctionTable < Test::Unit::TestCase

  def setup
    @function_table = FunctionTable.new
  end

  def test_add_function
    type = @function_table.add_function :func, Type.long

    assert_equal Type.long, type
    assert_equal Type.long, @function_table[:func]
  end

  def test_cheat
    @function_table.add_function :func, Type.long
    @function_table.add_function :func, Type.str

    assert_equal [Type.long, Type.str], @function_table.cheat(:func)
  end

  def test_has_key?
    @function_table.add_function :func, Type.long

    assert_equal true, @function_table.has_key?(:func)
    assert_equal false, @function_table.has_key?('no such func')
  end

  def test_index
    @function_table.add_function :func, Type.long

    assert_equal Type.long, @function_table[:func]

    @function_table.add_function :func, Type.str

    assert_equal Type.long, @function_table[:func]
  end

  def test_unify_one_type
    @function_table.add_function :func, Type.unknown

    @function_table.unify :func, Type.long do
      flunk "Block should not have been called"
    end

    assert_equal Type.long, @function_table[:func]
  end

  def test_unify_two_type
    @function_table.add_function :func, Type.unknown
    @function_table.add_function :func, Type.str

    @function_table.unify :func, Type.long do
      flunk "Block should not have been called"
    end

    assert_equal Type.long, @function_table[:func]
  end

  def test_unify_block_called_no_type
    @function_table.add_function :func, Type.str

    test_var = false

    @function_table.unify :func, Type.long do
      test_var = true
    end

    assert test_var, "Block not called"
  end

  def test_unify_block_called_no_unify
    test_var = false

    @function_table.unify :func, Type.long do
      test_var = true
    end

    assert test_var, "Block not called"
  end

end
