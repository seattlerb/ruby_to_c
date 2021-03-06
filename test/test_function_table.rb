#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'minitest/test'
require 'function_table'
require 'type'

class TestFunctionTable < Minitest::Test

  def setup
    @function_table = FunctionTable.new
  end

  def test_add_function
    type = @function_table.add_function :func, CType.long

    assert_equal CType.long, type
    assert_equal CType.long, @function_table[:func]
  end

  def test_cheat
    @function_table.add_function :func, CType.long
    @function_table.add_function :func, CType.str

    assert_equal [CType.long, CType.str], @function_table.cheat(:func)
  end

  def test_has_key?
    @function_table.add_function :func, CType.long

    assert_equal true, @function_table.has_key?(:func)
    assert_equal false, @function_table.has_key?('no such func')
  end

  def test_index
    @function_table.add_function :func, CType.long

    assert_equal CType.long, @function_table[:func]

    @function_table.add_function :func, CType.str

    assert_equal CType.long, @function_table[:func]
  end

  def test_unify_one_type
    @function_table.add_function :func, CType.unknown

    @function_table.unify :func, CType.long do
      flunk "Block should not have been called"
    end

    assert_equal CType.long, @function_table[:func]
  end

  def test_unify_two_type
    @function_table.add_function :func, CType.unknown
    @function_table.add_function :func, CType.str

    @function_table.unify :func, CType.long do
      flunk "Block should not have been called"
    end

    assert_equal CType.long, @function_table[:func]
  end

  def test_unify_block_called_no_type
    @function_table.add_function :func, CType.str

    test_var = false

    @function_table.unify :func, CType.long do
      test_var = true
    end

    assert test_var, "Block not called"
  end

  def test_unify_block_called_no_unify
    test_var = false

    @function_table.unify :func, CType.long do
      test_var = true
    end

    assert test_var, "Block not called"
  end

end
