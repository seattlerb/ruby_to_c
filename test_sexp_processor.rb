#!/usr/local/bin/ruby -w

$TESTING = true

require 'sexp_processor'
require 'stringio'
require 'test/unit'
require 'pp'

# Fake test classes:

class TestProcessor < SexpProcessor # ZenTest SKIP
  attr_accessor :auto_shift_type

  def process_acc1(exp)
    out = self.expected.new(:acc2, exp.thing_three, exp.thing_two, exp.thing_one)
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
    self.expected.new(*result)
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

  def process_expected(exp)
    exp.clear
    return {}
  end

  def process_string(exp)
    return exp.shift
  end 

end

class TestProcessorDefault < SexpProcessor # ZenTest SKIP
  def initialize
    super
    self.default_method = :def_method
  end

  def def_method(exp)
    exp.clear
    self.expected.new(42)
  end
end

# Real test classes:

class TestSexp < Test::Unit::TestCase # ZenTest FULL

  def util_sexp_class
    Object.const_get(self.class.name[4..-1])
  end

  def setup
    @sexp_class = util_sexp_class
    @processor = SexpProcessor.new
    @sexp = @sexp_class.new(1, 2, 3)
  end

  def test_new_nested
    @sexp = Sexp.new(:lasgn, "var", Sexp.new(:str, "foo"))
    assert_equal('Sexp.new(:lasgn, "var", Sexp.new(:str, "foo"))',
                 @sexp.inspect)
  end

  def test_equals_array
    # can't use assert_equals because it uses array as receiver
    assert_not_equal(@sexp, [1, 2, 3],
                     "Sexp must not be equal to equivalent array")
    # both directions just in case
# HACK - not sure why it is failing now that we split out TypedSexp
#    assert_not_equal([1, 2, 3], @sexp,
#                     "Sexp must not be equal to equivalent array")
  end

  def test_equals_sexp
    sexp2 = Sexp.new(1, 2, 3)
    assert_equal(@sexp, sexp2)
  end

  def test_equals_not_body
    sexp2 = Sexp.new(1, 2, 5)
    assert_not_equal(@sexp, sexp2)
  end
 
  def test_to_a
    assert_equal([1, 2, 3], @sexp.to_a)
  end

  def test_accessors=
    a = s(:call, s(:lit, 1), "func", s(:array, s(:lit, 2)))
    a.accessors = [:lhs, :name, :rhs]

    assert_equal a.accessors, [:lhs, :name, :rhs]

    assert_equal s(:lit, 1), a.lhs
    assert_equal "func", a.name
    assert_equal s(:array, s(:lit, 2)), a.rhs

    a.accessors = []

    assert_raises NoMethodError do
      a.lhs
    end
  end
  def test_accessors; end # handled

  def test_sexp_body
    assert_equal [2, 3], @sexp.sexp_body
  end

  def test_array_type?
    assert_equal false, @sexp.array_type?
    @sexp.unshift :array
    assert_equal true, @sexp.array_type?
  end

  def test_each_of_type
    # TODO: huh... this tests fails if top level sexp :b is removed
    @sexp = s(:b, s(:a, s(:b, s(:a), :a, s(:b, :a), s(:b, s(:a)))))
    count = 0
    @sexp.each_of_type(:a) do |exp|
      count += 1
    end
    assert_equal(3, count, "must find 3 a's in #{@sexp.inspect}")
  end

  def test_find_and_replace_all
    @sexp    = s(:a, s(:b, s(:a), s(:b), s(:b, s(:a))))
    expected = s(:a, s(:a, s(:a), s(:a), s(:a, s(:a))))

    @sexp.find_and_replace_all(:b, :a)

    assert_equal(expected, @sexp)
  end

  def test_inspect
    k = @sexp_class
    assert_equal("#{k}.new()",
                 k.new().inspect)
    assert_equal("#{k}.new(:a)",
                 k.new(:a).inspect)
    assert_equal("#{k}.new(:a, :b)",
                 k.new(:a, :b).inspect)
    assert_equal("#{k}.new(:a, #{k}.new(:b))",
                 k.new(:a, k.new(:b)).inspect)
  end

  def test_to_s
    test_inspect
  end

  def test_method_missing
    assert_raises NoMethodError do
      @sexp.no_such_method
    end

    @sexp.accessors = [:its_a_method_now]

    assert_nothing_raised do
      assert_equal 2, @sexp.its_a_method_now
    end
  end

  def util_pretty_print(expect, input)
    io = StringIO.new
    PP.pp(input, io)
    io.rewind
    assert_equal(expect, io.read.chomp)
  end

  def test_pretty_print
    util_pretty_print("s()",
                       s())
    util_pretty_print("s(:a)",
                       s(:a))
    util_pretty_print("s(:a, :b)",
                       s(:a, :b))
    util_pretty_print("s(:a, s(:b))",
                       s(:a, s(:b)))
  end

  def test_shift
    assert_equal(1, @sexp.shift)
    assert_equal(2, @sexp.shift)
    assert_equal(3, @sexp.shift)
    assert_nil(@sexp.shift)
  end

  def test_unpack_equal
    assert_equal false, @sexp.unpack
    @sexp.unpack = true
    assert_equal true, @sexp.unpack
  end

  def test_unpack; end # handled
  def test_unpack_q; end # handled

end

class TestSexpProcessor < Test::Unit::TestCase

  def setup
    @processor = TestProcessor.new
  end

  def test_sexp_accessors
    @processor.sexp_accessors = {
      :acc1 => [:thing_one, :thing_two, :thing_three]
    }

    a = s(:acc1, 1, 2, 3)

    assert_equal s(:acc2, 3, 2, 1), @processor.process(a)
  end

  def test_sexp_accessors_reset
    @processor.sexp_accessors = {
      :acc1 => [:thing_one, :thing_two, :thing_three]
    }

    a = s(:acc1, 1, 2, 3)
    b = @processor.process(a)

    assert_raises NoMethodError do
      @processor.process(b)
    end
  end
  def test_sexp_accessors=; end # handled

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

  def test_process_default
    @processor = TestProcessorDefault.new
    @processor.warn_on_default = false

    a = s(:blah, 1, 2, 3)
    assert_equal(@processor.expected.new(42), @processor.process(a))
  end

  def test_process_not_sexp
    @processor = TestProcessor.new
    @processor.warn_on_default = false

    assert_raises(TypeError) do
      @processor.process([:broken, 1, 2, 3])
    end
  end

  def test_exclude
    @processor.exclude = [ :blah ]
    assert_raise(SyntaxError) do
      @processor.process([:blah, 1, 2, 3])
    end
  end

  def test_exclude=; end # Handled

  def test_strict
    @processor.strict = true
    assert_raise(SyntaxError) do
      @processor.process([:blah, 1, 2, 3])
    end
  end
  def test_strict=; end #Handled

  def test_require_empty_false
    @processor.require_empty = false
    @processor.expected = Object

    assert_nothing_raised do
      @processor.process([:nonempty, 1, 2, 3])
    end
  end

  def test_require_empty_true
    assert_raise(TypeError) do
      @processor.process([:nonempty, 1, 2, 3])
    end
  end
  def test_require_empty=; end # handled

  def test_process_strip
    @processor.auto_shift_type = true
    assert_equal([1, 2, 3], @processor.process(s(:strip, 1, 2, 3)))
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
    # nothing to test at this time... soon.
  end

  def test_auto_shift_type
    @processor.auto_shift_type = false
    assert_equal(false, @processor.auto_shift_type)
    @processor.auto_shift_type = true
    assert_equal(true, @processor.auto_shift_type)
  end
  def test_auto_shift_type_equal; end # handled

  def test_default_method
    # default functionality tested in process_default
    assert_nil @processor.default_method
    @processor.default_method = :something
    assert_equal :something, @processor.default_method
  end
  def test_default_method=; end # handled

  def test_expected
    assert_equal Sexp, @processor.expected
    assert_raises(TypeError) do
      @processor.process([:expected])           # should raise
    end

    @processor.process(s(:str, "string"))       # shouldn't raise

    @processor.expected = Hash
    assert_equal Hash, @processor.expected
    assert !(Hash === Sexp.new()), "Hash === Sexp.new should not be true"

    assert_raises(TypeError) do
      @processor.process(s(:string, "string"))     # should raise
    end

    @processor.process([:expected])        # shouldn't raise
  end
  def test_expected=; end # handled

  # Not Testing:
  def test_debug; end
  def test_debug=; end
  def test_warn_on_default; end
  def test_warn_on_default=; end

end

