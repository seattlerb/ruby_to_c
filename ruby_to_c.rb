#!/usr/local/bin/ruby -w

require 'parse_tree'

class Array
  def second
    self[1]
  end
end

class RubyToC

  def self.translate_all_of(klass)

    methods = []
    klass.instance_methods(false).sort.each do |meth|
      methods << self.new(klass, meth).translate
    end

    return methods.join("\n\n")
  end

  def initialize(klass, meth)
    @return_type = nil
    @tokens = ParseTree.new.parse_tree(klass, meth)
    @size = {}
  end

  def translate
    type = @tokens.shift
    case type
    when :defn then
#      @tokens.shift
      return self.parse_defn
    else
      raise "unknown type #{type}"
    end
  end

  def parse_defn
    name = @tokens.shift
    args = []
    code = []

    if @tokens.first.kind_of? Array then
      scope = @tokens.shift
      type = scope.shift
      case type
      when :scope then
	args, code = self.parse_scope(scope)
	args = args.map { |a| "long #{a}" }
      else
	raise "unknown type #{type}"
      end
      code << '' # HACK - um. yeah
    else
      raise "parse error in #{name}: #{@tokens.first.inspect}"
    end

    @return_type = "void" if @return_type.nil?

    return "#{@return_type}\n#{name}(#{args.join(", ")}) {\n#{code.join(";\n")}}"
  end

  def parse_scope(tokens)
    args = []
    code = []
    if tokens.first.kind_of? Array then
      t = tokens.shift
      type = t.shift
      case type
      when :args then
	args = t
      when :block then
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
    args = []
    code = []

    tokens.each do |chunk|
      type = chunk.shift
      case type
      when :args then
	args = chunk
      when :fcall then
	code << parse_fcall(chunk)
      when :if then
	code << parse_if(chunk)
      when :lasgn then
	lhs = chunk.shift
	rhs = parse_thingy(chunk.shift).first
	@size[lhs.intern] = @size[rhs.intern] # HACK HACK HACK
	code << "long #{lhs}[] = #{rhs}"
      when :iter then
	# [:iter, 
	#    [:call, [:lvar, "array"], "each"],
	#    [:dasgn_curr, "x"],
	#    [:fcall, "puts", [:array, [:dvar, "x"]]]]
	lhs = parse_thingy(chunk.shift[1]).first
	var_name = chunk.shift[1]
	body = []
	chunk.each do |stmt|
	  body << parse_thingy(stmt).first
	end

	hack_size = @size[lhs.intern]
	code << "unsigned long index"
	code << "for (index = 0; index < #{hack_size}; ++index) {\nlong #{var_name} = #{lhs}[index]"
	code.push(*body)
	code << "}"

      else
	raise "unknown type #{type}"
      end
    end

    return args, code

  end

  def parse_fcall(tokens)
    code = []
    name = tokens.shift
    args = tokens.shift

    type = args.shift
    if type == :array then
      args.each do |chunk|
	type = chunk.shift
	case type
	when :lit then
	  code << chunk.shift
	when :lvar, :dvar then
	  code << chunk.shift
	when :call then
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

  def parse_if(tokens)
    conditional = parse_thingy(tokens.shift)
    if_true = parse_thingy(tokens.shift)
    if_false = parse_thingy(tokens.shift)
 
    result = "if (#{conditional}) {\n#{if_true};\n} else {\n#{if_false};\n}"
    return result
  end

  # TODO: check the grammar if make this a proper parse_expression
  def parse_thingy(tokens)
    code = []
    type = tokens.shift
    case type
    when :lit then
      code << tokens.shift
    when :lvar, :dvar then
      code << tokens.shift
    when :if then
      code << parse_if(tokens)
    when :fcall then
      code << parse_fcall(tokens)
    when :call then
      code << parse_call(tokens)
    when :array then
      a = []
      tokens.each do |chunk|
	a << parse_thingy(chunk)
      end
      c = "{ #{a.join(", ")} }"
      @size[c.intern] = a.size
      code << c
    when :return then
      ret = tokens.shift
      if @return_type.nil? then
	if ret.first == :lit then
	  @return_type = "long"
	end
      end
      ret = parse_thingy(ret)

      code << "return #{ret}"
    else
      raise "unknown type #{type}"
    end
    return code
  end

  def parse_call(tokens)
    lhs = tokens.shift
    name = tokens.shift
    rhs = tokens.shift

    type = lhs.shift
    case type
    when :lit then
      lhs = lhs.shift
    when :lvar then
      lhs = lhs.shift
    when :call then
      lhs = parse_call(lhs)
    else
      raise "unknown type #{type}"
    end

    code = []

    if rhs then
      type = rhs.shift
      if type == :array then
	rhs.each do |chunk|
	  type = chunk.shift
	  case type
	  when :lit then
	    code << chunk.shift
	  when :lvar then
	    code << chunk.shift
	  when :call then
	    code << parse_call(chunk)
	  else
	    raise "unknown type #{type}"
	  end
	end
      else
	raise "unknown type #{type}"
      end
    end

    case name
    when "==", "<", "<=", ">", ">=", "!=" then
      result = "#{lhs} #{name} #{code.first}"
    when "+", "-", "*", "/", "%" then
      result = "#{lhs} #{name} #{code.first}"
    else
      result = "#{lhs}.#{name}(#{code.join(", ")})"    
    end

    return result
  end

end
