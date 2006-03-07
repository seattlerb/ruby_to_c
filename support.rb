
class Environment

  attr_accessor :env

  def initialize
    @env = [{}]
  end

  def depth
    @env.length
  end

  def add(id, val)
    raise "Adding illegal identifier #{id.inspect}" unless Symbol === id
    current[id.to_s.sub(/^\*/, '').intern] = val
    # current[id] = val
  end

  def extend
    @env.unshift({})
  end

  def unextend
    @env.shift
  end

  def lookup(id)

    warn "#{id} is a string from #{caller[0]}" if String === id

    # HACK: if id is :self, cheat for now until we have full defn remapping
    if id == :self then
      return Type.fucked
    end

    @env.each do |closure|
      return closure[id] if closure.has_key? id
    end

    raise NameError, "Unbound var: #{id.inspect} in #{@env.inspect}"
  end

  def current
    @env.first
  end

  def scope
    self.extend
    yield
    self.unextend
  end

end

class FunctionTable

  def initialize
    @functions = Hash.new do |h,k|
      h[k] = []
    end
  end

  def cheat(name) # HACK: just here for debugging
    puts "\n# WARNING: FunctionTable.cheat called from #{caller[0]}" if $DEBUG
    @functions[name]
  end

  def [](name) # HACK: just here for transition
    puts "\n# WARNING: FunctionTable.[] called from #{caller[0]}" if $DEBUG
    @functions[name].first
  end

  def has_key?(name) # HACK: just here for transition
    puts "\n# WARNING: FunctionTable.has_key? called from #{caller[0]}" if $DEBUG
    @functions.has_key?(name)
  end

  def add_function(name, type)
    @functions[name] << type
    type
  end

  def unify(name, type)
    success = false
    @functions[name].each do |o| # unify(type)
      begin
        o.unify type
        success = true
      rescue
        # ignore
      end
    end
    unless success then
      yield(name, type) if block_given?
    end
    type
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
    raise TypeError, "Unable to unify: different number of args #{self.inspect} vs #{other.inspect}" unless
      @formal_types.length == other.formal_types.length

    @formal_types.each_with_index do |t, i|
      t.unify other.formal_types[i]
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

##
# Unique creates unique variable names.

class Unique

  ##
  # Variable names will be prefixed by +prefix+

  def initialize(prefix)
    @prefix = prefix
    @curr = 'a'
  end

  ##
  # Generate a new unique variable name

  def next
    var = "#{@prefix}_#{@curr}"
    @curr.succ!
    return var
  end

end

