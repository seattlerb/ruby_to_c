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

    @tokens = @ruby.parse_tree(klass, meth)

    methods = []

    while @tokens.first == :defn do
      @tokens.shift
      methods << self.parse_defn
      p @tokens
    end

    return methods.join("\n\n")
  end

  def parse_defn
    name = @tokens.shift
    args = []
    code = []

    if @tokens.first.kind_of? Array then
      scope = @tokens.shift
      type = scope.shift
      if type == :scope then
	args, code = self.parse_scope(scope)
      else
	raise "unknown type #{type}"
      end
      code << '' # HACK - um. yeah
    else
      raise "parse error"
    end

    return "void\n#{name}(#{args.join(", ")}) {\n#{code.join(";\n")}}"
  end

  def parse_scope(tokens)
    args = []
    code = []
    if tokens.first.kind_of? Array then
      t = tokens.shift
      type = t.shift
      if type == :args then
	args = t
      elsif type == :block then
	args, code = parse_block(t)
      else
	raise "unknown type #{type}"
      end
    else
      raise "unknown #{s.first.inspect}"
    end
    return args, code
  end

  def parse_block(tokens)
    puts "parse_block"
    p tokens

    args = []
    code = []

    tokens.each do |chunk|
      type = chunk.shift
      if type == :args then
	args = chunk
      elsif type == :fcall then
	code << parse_fcall(chunk)
      else
	raise "unknown type #{type}"
      end
    end

    return args, code

  end

  def parse_fcall(tokens)
    code = []

    puts "parse_fcall"
    p tokens

    name = tokens.shift
    args = tokens.shift

    type = args.shift
    if type == :array then
      args.each do |chunk|
	type = chunk.shift
	case type
	when :lit
	  code << chunk.shift
	when :lvar
	  code << chunk.shift
	when :call
	  code << parse_call(chunk)
	else
	  raise "unknown type #{type}"
	end
      end
    else
      raise "unknown type #{type}"
    end

    return "#{name}(#{code.join(", ")})"

  end

  def parse_call(tokens)
    puts "parse_call"

    lhs = tokens.shift
    name = tokens.shift
    rhs = tokens.shift

    p lhs
    p name
    p rhs

    type = lhs.shift
    case type
    when :lit
      lhs = lhs.shift
    when :lvar
      lhs = lhs.shift
    when :call
      lhs = parse_call(lhs)
    else
      raise "unknown type #{type}"
    end

    code = []
    type = rhs.shift
    if type == :array then
      rhs.each do |chunk|
	type = chunk.shift
	case type
	when :lit
	  code << chunk.shift
	when :lvar
	  code << chunk.shift
	when :call
	  code << parse_call(chunk)
	else
	  raise "unknown type #{type}"
	end
      end
    else
      raise "unknown type #{type}"
    end

    if lhs.kind_of? Numeric and code.size == 1 and code.first.kind_of? Numeric then
      result = "#{lhs} #{name} #{code.first}"
    else
      result = "#{lhs}.#{name}(#{code.join(", ")})"    
    end
    puts result
    return result
  end

end
