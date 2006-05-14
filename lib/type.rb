
require 'handle'
require 'function_type' # FIX? cycle

class Type

  # REFACTOR: nuke this
  KNOWN_TYPES = {
    :unknown => "Unknown",
    :unknown_list => "Unknown list",
    :long => "Integer",
    :long_list => "Integer list",
    :str => "String",
    :str_list => "String list",
    :void => "Void",
    :bool => "Bool",
    :bool_list => "Bool list",
    :value => "Value",
    :value_list => "Value list",
    :function => "Function",
    :file => "File",
    :float => "Float",
    :float_list => "Float list",
    :symbol => "Symbol",
    :zclass => "Class",
    :homo => "Homogenous",
    :hetero => "Heterogenous",
    :fucked => "Untranslatable type",
  }

  TYPES = {}

  def self.method_missing(type, *args)
    raise "Unknown type Type.#{type}" unless KNOWN_TYPES.has_key?(type)
    case type 
    when :unknown then
      return self.new(type)
    when :function then
      if args.size == 2 then
        $stderr.puts "\nWARNING: adding Type.unknown for #{caller[0]}" if $DEBUG
        args.unshift Type.unknown
      end
      return self.new(FunctionType.new(*args))
    else
      if type.to_s =~ /(.*)_list$/ then
        TYPES[type] = self.new($1.intern, true) unless TYPES.has_key?(type)
        return TYPES[type]
      else
        TYPES[type] = self.new(type) unless TYPES.has_key?(type)
        return TYPES[type]
      end
    end
  end

  def self.unknown_list
    self.new(:unknown, true)
  end

  attr_accessor :type
  attr_accessor :list

  def initialize(type, list=false)
    # HACK
    unless KNOWN_TYPES.has_key? type or type.class.name =~ /Type$/ then
      raise "Unknown type Type.new(#{type.inspect})"
    end
    @type = Handle.new type
    @list = list
  end

  def function?
    not KNOWN_TYPES.has_key? self.type.contents
  end

  def unknown?
    self.type.contents == :unknown
  end

  def list?
    @list
  end

  # REFACTOR: this should be named type, but that'll break code at the moment
  def list_type
    @type.contents
  end

  def eql?(other)
    return nil unless other.class == self.class

    other.type == self.type && other.list? == self.list?
  end

  alias :== :eql?

  def hash
    type.contents.hash ^ @list.hash
  end

  def unify(other)
    return other.unify(self) if Array === other
    return self if other == self and (not self.unknown?)
    return self if other.nil?
    if self.unknown? and other.unknown? then
      # link types between unknowns
      self.type = other.type
      self.list = other.list? or self.list? # HACK may need to be tri-state
    elsif self.unknown? then
      # other's type is now my type
      self.type.contents = other.type.contents
      self.list = other.list?
    elsif other.unknown? then
      # my type is now other's type
      other.type.contents = self.type.contents
      other.list = self.list?
    elsif self.function? and other.function? then
      self_fun = self.type.contents
      other_fun = other.type.contents

      self_fun.unify_components other_fun
    else
      raise TypeError, "Unable to unify #{self.inspect} with #{other.inspect}"
    end
    return self
  end

  def to_s
    str = "Type.#{self.type.contents}"
    str << "_list" if self.list?
    str
  end

  def inspect
    to_s
  end unless $DEBUG

end
