#!/usr/local/bin/ruby -w

require 'sexp_processor'
require 'support'
require 'test/unit'

# Fake test classes:

class TestProcessor < SexpProcessor
  attr_accessor :auto_shift_type

  def process_specific(exp)
    result = exp[1..-1]
    exp.clear
    Sexp.new(*result)
  end

  def process_strip(exp)
    result = exp.deep_clone
    exp.clear
    result
  end

  def process_nonempty(exp)
    exp
  end

  def process_broken(exp)
    result = [*exp]
    exp.clear
    result
  end

end

class TestProcessorDefault < SexpProcessor
  def initialize
    super
    self.default_method = :def_method
  end

  def def_method(exp)
    exp.clear
    Sexp.new(42)
  end
end

# Real test classes:

class TestSexp < Test::Unit::TestCase # ZenTest FULL

  def setup
    @sexp = Sexp.new(1, 2, 3)
    @sexp.sexp_type = 42
  end

  def test_from_array_normal
    @sexp = Sexp.from_array([1, 2, 3])
    expected = Sexp.new(1, 2, 3)
    assert_equal(expected, @sexp)
  end

  def test_from_array_type
    @sexp = Sexp.from_array([1, 2, 3, Type.str])
    expected = Sexp.new(1, 2, 3, Type.str)
    assert_equal(expected, @sexp)
  end

  def test_from_array_nested
    @sexp = Sexp.from_array([1, [2, Type.long], 3, Type.unknown])
    expected = Sexp.new(1, Sexp.new(2, Type.long), 3, Type.unknown)
    assert_equal(Sexp.new(2, Type.long), @sexp[1])
    assert_equal(expected, @sexp)
  end

  def test_new_nested
    @sexp = Sexp.new(:lasgn, "var", Sexp.new(:str, "foo", Type.str), Type.str)
    assert_equal('Sexp.new(:lasgn, "var", Sexp.new(:str, "foo", Type.str), Type.str)',
                 @sexp.inspect)
  end

  def test_sexp_type
    assert_equal(42, @sexp.sexp_type)
  end

  def test_sexp_type=
    assert_equal(42, @sexp.sexp_type)
    @sexp.sexp_type = 24
    assert_equal(24, @sexp.sexp_type)
  end

  def test_sexp_type_array_homo
    @sexp = Sexp.new(:array, Sexp.new(:lit, 1, Type.long),
                     Sexp.new(:lit, 2, Type.long))
    assert_equal(Type.homo, @sexp.sexp_type)
    assert_equal([Type.long, Type.long], @sexp.sexp_types)
  end

  def test_sexp_type_array_hetero
    @sexp = Sexp.new(:array, Sexp.new(:lit, 1, Type.long),
                     Sexp.new(:str, "foo", Type.str))
    assert_equal(Type.hetero, @sexp.sexp_type)
    assert_equal([Type.long, Type.str], @sexp.sexp_types)
  end

  def test_sexp_type_array_nested
    @sexp = Sexp.new(:array, Sexp.new(:lit, 1, Type.long),
                     Sexp.new(:array, Sexp.new(:lit, 1, Type.long)))
    assert_equal(Type.hetero, @sexp.sexp_type)
    assert_equal([Type.long, Type.homo], @sexp.sexp_types)
  end

  def test_equals_array
    # can't use assert_equals because it uses array as receiver
    @sexp.sexp_type = Type.str
    assert(@sexp == [1, 2, 3, Type.str],
           "Sexp must be equal to equivalent array")
  end

  def test_equals_sexp
    sexp2 = Sexp.new(1, 2, 3)
    sexp2.sexp_type = 42
    assert_equal(@sexp, sexp2)
  end

  def test_equals_not_body
    sexp2 = Sexp.new(1, 2, 5)
    sexp2.sexp_type = 42
    assert_not_equal(@sexp, sexp2)
  end

  def test_equals_not_type
    sexp2 = Sexp.new(1, 2, 3)
    sexp2.sexp_type = 24
    assert_not_equal(@sexp, sexp2)
  end

  def test_to_a
    assert_equal([1, 2, 3, 42], @sexp.to_a)
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

  def test_process_default
    @processor = TestProcessorDefault.new
    @processor.warn_on_default = false

    a = Sexp.new(:blah, 1, 2, 3)
    assert_equal(Sexp.new(42), @processor.process(a))
  end

  def test_process_not_sexp
    @processor = TestProcessor.new
    @processor.warn_on_default = false

    assert_raises(RuntimeError) do
      @processor.process([:broken, 1, 2, 3])
    end
  end

  def test_exclude
    @processor.exclude = [ :blah ]
    assert_raise(SyntaxError) do
      @processor.process([:blah, 1, 2, 3])
    end
  end

  def test_strict
    @processor.strict = true
    assert_raise(SyntaxError) do
      @processor.process([:blah, 1, 2, 3])
    end
  end

  def test_process_strip
    @processor.auto_shift_type = true
    assert_equal([1, 2, 3], @processor.process(Sexp.new(:strip, 1, 2, 3)))
  end

  def test_assert_type_hit
    assert_nothing_raised do
      @processor.assert_type([:blah, 1, 2, 3], :blah)
    end
  end

  def test_assert_type_miss
    assert_raise(TypeError) do
      @processor.assert_type([:thingy, 1, 2, 3], :blah)
    end
  end

  def test_generate
# HACK    raise NotImplementedError, 'Need to write test_generate'
  end
end

