#!/usr/local/bin/ruby -w

$TESTING = true

require 'minitest/autorun' if $0 == __FILE__
require 'rewriter'
require 'r2ctestcase'

ParseTreeTestCase.testcase_order << "Rewriter"

class TestRewriter < R2CTestCase
  def setup
    super
    @processor = Rewriter.new
  end
end
