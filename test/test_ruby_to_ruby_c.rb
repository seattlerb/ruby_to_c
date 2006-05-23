#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'
require 'ruby_to_ruby_c'
require 'r2ctestcase'

# TODO: maybe make this a subclass of TestRubyToAnsiC??? might be a bad idea
class TestRubyToRubyC < R2CTestCase

  def setup
    @ruby_to_c = RubyToRubyC.new
    @ruby_to_c.env.extend
    @processor = @ruby_to_c
  end

  def test_translator
    Object.class_eval "class Suck; end"
    input = [:class, :Suck, :Object,
      [:defn, :something, [:scope, [:block, [:args], [:fcall, :"whaaa\?"]]]],
      [:defn, :foo, [:scope, [:block, [:args], [:vcall, :something]]]]]
    expected = "// class Suck < Object\n\nVALUE\nsomething() {\nrb_funcall(self, rb_intern(\"whaaa?\"), 0);\n}\n\nVALUE\nfoo() {\nrb_funcall(self, rb_intern(\"something\"), 0);\n}"
    assert_equal expected, RubyToRubyC.translator.process(input)
  end

end
