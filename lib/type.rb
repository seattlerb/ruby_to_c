
require 'handle'
require 'function_type'

class CType

  # REFACTOR: nuke this
  KNOWN_TYPES = {
    :bool         => "Bool",
    :bool_list    => "Bool list",
    :const        => "Const",
    :file         => "File",
    :float        => "Float",
    :float_list   => "Float list",
    :function     => "Function",
    :long         => "Integer",
    :long_list    => "Integer list",
    :range        => "Range",
    :regexp       => "Regular Expression",
    :str          => "String",
    :str_list     => "String list",
    :symbol       => "Symbol",
    :value        => "Value",
    :value_list   => "Value list",
    :void         => "Void",
    :zclass       => "Class",

    :fucked       => "Untranslatable type",
    :hetero       => "Heterogenous",
    :homo         => "Homogenous",
    :unknown      => "Unknown",
    :unknown_list => "Unknown list",
  }

  TYPES = {}

  def self.function lhs_type, arg_types, return_type = nil
    unless return_type then
      $stderr.puts "\nWARNING: adding Type.unknown for #{caller[0]}" if $DEBUG
      # TODO: gross, maybe go back to the *args version from method_missing
      return_type = arg_types
      arg_types = lhs_type
      lhs_type = CType.unknown
    end

    self.new FunctionType.new(lhs_type, arg_types, return_type)
  end

  def self.unknown
    self.new :unknown
  end

  def self.method_missing(type, *args)
    raise "Unknown type Type.#{type} (#{type.inspect})" unless
      KNOWN_TYPES.has_key?(type)

    if type.to_s =~ /(.*)_list$/ then
      TYPES[type] = self.new($1.intern, true) unless TYPES.has_key?(type)
      return TYPES[type]
    else
      TYPES[type] = self.new(type) unless TYPES.has_key?(type)
      return TYPES[type]
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
