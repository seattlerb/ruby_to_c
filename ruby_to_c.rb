#!/usr/local/bin/ruby -w

require 'parse_tree'

class Array
  def second
    self[1]
  end
end

class RubyToC

  def initialize
    @ruby = ParseTree.new
  end

  def translate(klass, meth=nil)
    "no"
  end

end
