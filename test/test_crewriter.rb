$TESTING = true

begin require 'rubygems'; rescue LoadError; end
require 'test/unit' if $0 == __FILE__
require 'crewriter'
require 'r2ctestcase'

class TestCRewriter < R2CTestCase

  def setup
    @processor = CRewriter.new
    @rewrite = CRewriter.new
  end

  def xtest_process_call_rewritten

    input = t(:call,
              t(:str, "this", Type.str),
              :+,
              t(:array, t(:str, "that", Type.str)),
              Type.str)
    expected = t(:call,
                 nil,
                 :strcat,
                 t(:array,
                   t(:str, "this", Type.str),
                   t(:str, "that", Type.str)),
                 Type.str)

    assert_equal expected, @rewrite.process(input)
  end

  def xtest_process_call_same

    input = t(:call,
              t(:lit, 1, Type.long),
              :+,
              t(:array, t(:lit, 2, Type.long)),
              Type.long)
    expected = input.deep_clone

    assert_equal expected, @rewrite.process(input)
  end
end
