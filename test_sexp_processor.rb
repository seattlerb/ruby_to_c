
require 'sexp_processor'
require 'test/unit'

class TestProcessor < SexpProcessor
  attr_accessor :auto_shift_type

  def process_specific(exp)
    result = exp[1..-1]
    exp.clear
    result
  end

  def process_strip(exp)
    result = exp.deep_clone
    exp.clear
    result
  end

  def process_nonempty(exp)
    exp
  end
end

class TestSexpProcessor < Test::Unit::TestCase

  def setup
    @processor = TestProcessor.new
  end

  def test_process_specific
    a = [:specific, 1, 2, 3]
    assert_equal(a[1..-1], @processor.process(a))
  end

  def test_process_general
    a = [:blah, 1, 2, 3]
    assert_equal(a.deep_clone, @processor.process(a))
  end

  def test_process_nonempty
    assert_raise(RuntimeError) do
      @processor.process([:nonempty, 1, 2, 3])
    end
  end

  def test_process_strip
    @processor.auto_shift_type = true
    assert_equal([1, 2, 3], @processor.process([:strip, 1, 2, 3]))
  end

  def test_assert_type_hit
    assert_nothing_raised do
      @processor.assert_type(:blah, [:blah, 1, 2, 3])
    end
  end

  def test_assert_type_miss
    assert_raise(TypeError) do
      @processor.assert_type(:blah, [:thingy, 1, 2, 3])
    end
  end

  def test_generate
# HACK    raise NotImplementedError, 'Need to write test_generate'
  end
end

