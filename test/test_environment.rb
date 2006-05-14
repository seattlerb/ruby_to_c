#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'
require 'environment'

class TestEnvironment < Test::Unit::TestCase

  def setup
    @env = Environment.new
  end

  def test_add
    assert_equal 42, @env.add(:var, 42)
    assert_equal 42, @env.lookup(:var)
  end

  def test_add_depth
    @env.scope do
      assert_equal 42, @env.add(:var, 42, 1)
    end
    assert_equal 42, @env.lookup(:var)
  end

  def test_add_raises_on_illegal
    assert_raises RuntimeError do
      @env.add nil, 1
    end

    assert_raises RuntimeError do
      @env.add 1, :foo
    end
  end

  def test_add_segmented
    @env.scope do
      @env.add :var, 42
      assert_equal 42, @env.lookup(:var)
    end

    assert_raises NameError do
      @env.lookup(:var)
    end
  end

  def test_current
    @env.add :var, 42
    
    expected = { :var => 42 }
    assert_equal expected, @env.current
  end

  def test_all
    @env.scope do
      @env.add :x, 42
      @env.scope do
        @env.add :y, 24
        @env.add :x, 15
        expected = { :x => 15, :y => 24 }

        assert_equal expected, @env.all
      end
    end
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
    @env.add :var, 1
    assert_equal 1, @env.lookup(:var)
  end

  def test_lookup_raises
    assert_raises NameError do
      @env.lookup(:var)
    end
  end

  def test_lookup_extended
    @env.add :var, 1
    assert_equal 1, @env.lookup(:var)

    @env.scope do
      assert_equal 1, @env.lookup(:var)
    end
  end

  def test_scope
    @env.add :var, 1
    assert_equal 1, @env.lookup(:var)

    @env.scope do
      @env.add :var, 2
      assert_equal 2, @env.lookup(:var)
    end

    assert_equal 1, @env.lookup(:var)
  end

  def test_scope_raise
    @env.add :a, 2

    begin
      @env.scope do
        @env.add :a, 1
        @env.add :b, 2
        raise "woo"
      end
    rescue
      # should replicate baddies
    end

    expected = { :a => 2 }
    assert_equal expected, @env.all
  end

  def test_unextend
    @env.extend

    @env.add :var, 1

    assert_equal 1, @env.lookup(:var)

    @env.unextend

    assert_raises NameError do
      @env.lookup :var
    end
  end

end
