
class Environment

  attr_accessor :env
  def initialize
    @env = []
  end

  def depth
    @env.length
  end

  def add(id, val)
    @env[0][id] = val
  end

  def extend
    @env.unshift({})
  end

  def unextend
    @env.shift
  end

  def lookup(id)
    @env.each do |closure|
      return closure[id] if closure.has_key? id
    end

    raise "Unbound var: #{id}"
  end

  def current
    @env.first
  end

end

class FunctionType

  attr_accessor :receiver_type
  attr_accessor :formal_types
  attr_accessor :return_type

  def initialize(receiver_type, formal_types, return_type)
    raise "nil not allowed" if formal_types.nil? or return_type.nil?
    @receiver_type = receiver_type
    @formal_types = formal_types
    @return_type = return_type
  end

  def ==(other)
    return nil unless other.class == self.class

    return false unless other.receiver_type == self.receiver_type
    return false unless other.return_type == self.return_type
    return false unless other.formal_types == self.formal_types
    return true
  end

  def unify_components(other)
    raise "Unable to unify: different number of args #{self.inspect} vs #{other.inspect}" unless
      @formal_types.length == other.formal_types.length

    @formal_types.each_with_index do |type, i|
      type.unify other.formal_types[i]
    end

    @receiver_type.unify other.receiver_type
    @return_type.unify other.return_type
#  rescue RuntimeError # print more complete warning message
#    raise "Unable to unify\n#{self}\nwith\n#{other}"
  end

  def to_s
    formals = formal_types.map do |t|
      t.inspect
    end

    "function(#{receiver_type.inspect}, [#{formals.join ', '}], #{return_type.inspect})"
  end

end

class Functions < Hash

  def [](name)
    super(name).deep_clone
  end

end

class Handle

  attr_accessor :contents

  def initialize(contents)
    @contents = contents
  end

  def ==(other)
    return nil unless other.class == self.class
    return other.contents == self.contents
  end

end

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
    :homo => "Homogenous",
    :hetero => "Heterogenous",
  }

  TYPES = {}

  def self.method_missing(type, *args)
    raise "Unknown type #{type}" unless KNOWN_TYPES.has_key?(type)
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
      raise "Unknown type #{type.inspect}"
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
      raise "Unable to unify #{self.inspect} with #{other.inspect}"
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

