#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'minitest/test'
require 'r2cenvironment'
require 'type'

class TestR2CEnvironment < Minitest::Test

  def setup
    @env = R2CEnvironment.new
  end

  def test_add
    assert_equal CType.long, @env.add(:var, CType.long)
    assert_equal CType.long, @env.lookup(:var)
  end

  def test_add_depth
    @env.scope do
      assert_equal CType.long, @env.add(:var, CType.long, 1)
    end
    assert_equal CType.long, @env.lookup(:var)
  end

  def test_add_raises_on_illegal
    assert_raises RuntimeError do
      @env.add nil, CType.long
    end

    assert_raises RuntimeError do
      @env.add 1, :foo
    end
  end

  def test_add_segmented
    @env.scope do
      @env.add :var, CType.long
      assert_equal CType.long, @env.lookup(:var)
    end

    assert_raises NameError do
      @env.lookup(:var)
    end
  end

  def test_current
    @env.add :var, CType.long
    @env.set_val :var, 42

    expected = { :var => [CType.long, 42] }
    assert_equal expected, @env.current
  end

  def test_all
    @env.scope do
      @env.add :x, CType.long

      @env.scope do
        @env.add :y, CType.str
        @env.add :x, CType.float

        expected = { :x => [CType.float], :y => [CType.str] }
        assert_equal expected, @env.all
      end

      expected = { :x => [CType.long] }
      assert_equal expected, @env.all
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

  def test_get_val
    @env.add :var, CType.long
    @env.set_val :var, 42

    assert_equal 42, @env.get_val(:var)
  end

  def test_set_val
    @env.add :var, CType.long
    assert_equal 42, @env.set_val(:var, 42)

    assert_equal 42, @env.get_val(:var)
  end

  def test_set_val_static_array
    @env.add :var, CType.long
    assert_equal "[2]", @env.set_val(:var, "[2]")

    assert_equal "[2]", @env.get_val(:var)
  end

  def test_get_val_unset
    @env.add :var, CType.long

    assert_nil @env.get_val(:var)
  end

  def test_get_val_unknown
    assert_raises(NameError) do
      @env.get_val(:unknown)
    end
  end

  def test_extend
    assert_equal [{}], @env.env

    @env.extend
    assert_equal [{}, {}], @env.env
  end

  def test_lookup
    @env.add :var, CType.long
    assert_equal CType.long, @env.lookup(:var)
  end

  def test_lookup_raises
    assert_raises NameError do
      @env.lookup(:var)
    end
  end

  def test_lookup_scope
    @env.add :var, CType.long
    assert_equal CType.long, @env.lookup(:var)

    @env.scope do
      assert_equal CType.long, @env.lookup(:var)
    end
  end

  def test_scope
    @env.add :var, CType.long
    assert_equal CType.long, @env.lookup(:var)

    @env.scope do
      @env.add :var, CType.float
      assert_equal CType.float, @env.lookup(:var)
    end

    assert_equal CType.long, @env.lookup(:var)
  end

  def test_scope_raise
    @env.add :a, CType.float

    begin
      @env.scope do
        @env.add :a, CType.long
        @env.add :b, CType.long
        raise "woo"
      end
    rescue
      # should replicate baddies
    end

    expected = { :a => [CType.float] }
    assert_equal expected, @env.all
  end

  def test_unextend
    @env.extend

    @env.add :var, CType.long

    assert_equal CType.long, @env.lookup(:var)

    @env.unextend

    assert_raises NameError do
      @env.lookup :var
    end
  end

end
