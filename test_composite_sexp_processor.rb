#!/usr/local/bin/ruby -w

$TESTING = true

require 'composite_sexp_processor'
require 'test/unit'

class FakeProcessor1 < SexpProcessor # ZenTest SKIP

  def initialize
    super
    self.warn_on_default = false
    self.default_method = :default_processor
    self.expected = Array
  end

  def default_processor(exp)
    result = []
    until exp.empty? do
      result << exp.shift.to_s + " woot"
    end
    result
  end
end

class TestCompositeSexpProcessor < Test::Unit::TestCase

  def setup
    @p = CompositeSexpProcessor.new
  end

  def test_process_default
    data = [1, 2, 3]
    result = @p.process(data.dup)
    assert_equal(data.dup, result)
  end

  def test_process_fake1
    data = [1, 2, 3]
    @p << FakeProcessor1.new
    result = @p.process(data.dup)
    assert_equal(data.map {|x| "#{x} woot"}, result)
  end

  def test_process_fake1_twice
    data = [1, 2, 3]
    @p << FakeProcessor1.new
    @p << FakeProcessor1.new
    result = @p.process(data.dup)
    assert_equal(data.map {|x| "#{x} woot woot"}, result)
  end

  def test_processors
    # everything is tested by test_append
  end

  def test_append
    assert_equal([], @p.processors)

    assert_raises(ArgumentError) do
      @p << 42
    end

    fp1 = FakeProcessor1.new
    @p << fp1
    assert_equal([fp1], @p.processors)
  end

end
