#!/usr/local/bin/ruby -w

require 'sexp_processor'
require 'support'
require 'test/unit'

# Fake test classes:

class TestProcessor < SexpProcessor
  attr_accessor :auto_shift_type

  def process_acc1(exp)
    out = s(:acc2, exp.thing_three, exp.thing_two, exp.thing_one)
    exp.clear
    return out
  end

  def process_acc2(exp)
    out = []
    out << exp.thing_one
  end

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

  def test_new_nested
    @sexp = Sexp.new(:lasgn, "var", Sexp.new(:str, "foo", Type.str), Type.str)
    assert_equal('s(:lasgn, "var", s(:str, "foo", Type.str), Type.str)',
                 @sexp.inspect)
  end

  def test_sexp_type
    assert_equal(42, @sexp.sexp_type)
  end

  def test_sexp_type=
    assert_equal(42, @sexp.sexp_type)
    # FIX: we can't set sexp_type a second time, please expand tests
    @sexp._set_sexp_type 24
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
    @sexp._set_sexp_type Type.str
    assert_not_equal(@sexp, [1, 2, 3, Type.str],
                     "Sexp must not be equal to equivalent array")
    # both directions just in case
    assert_not_equal([1, 2, 3, Type.str], @sexp,
                     "Sexp must not be equal to equivalent array")
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

  def test_accessor
    a = s(:call, s(:lit, 1), "func", s(:array, s(:lit, 2)))
    a.accessors = [:lhs, :name, :rhs]

    assert_equal s(:lit, 1), a.lhs
    assert_equal "func", a.name
    assert_equal s(:array, s(:lit, 2)), a.rhs

    a.accessors = []

    assert_raises NoMethodError do
      a.lhs
    end
  end

  def test_body
    assert_equal [2, 3], @sexp.sexp_body
  end

end

class TestSexpProcessor < Test::Unit::TestCase

  def setup
    @processor = TestProcessor.new
  end

  def test_accessors
    @processor.sexp_accessors = {
      :acc1 => [:thing_one, :thing_two, :thing_three]
    }

    a = s(:acc1, 1, 2, 3)

    assert_equal s(:acc2, 3, 2, 1), @processor.process(a)
  end

  def test_accessors_reset
    @processor.sexp_accessors = {
      :acc1 => [:thing_one, :thing_two, :thing_three]
    }

    a = s(:acc1, 1, 2, 3)
    b = @processor.process(a)

    assert_raises NoMethodError do
      @processor.process(b)
    end
  end

  def test_process_specific
    a = [:specific, 1, 2, 3]
    expected = a[1..-1]
    assert_equal(expected, @processor.process(a))
  end

  def test_process_general
    a = [:blah, 1, 2, 3]
    expected = a.deep_clone
    assert_equal(expected, @processor.process(a))
  end

  def test_process_general_with_type
    a = Sexp.new(:blah, 1, 2, 3, Type.bool)
    expected = a.deep_clone
    assert_equal(expected, @processor.process(a))
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

  def test_require_empty_false
    @processor.require_empty = false
    @processor.expected = Object

    assert_nothing_raised do
      @processor.process([:nonempty, 1, 2, 3])
    end
  end

  def test_require_empty_true
    assert_raise(RuntimeError) do
      @processor.process([:nonempty, 1, 2, 3])
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

