
require 'support'

$TESTING = false unless defined? $TESTING

class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

class Sexp < Array # ZenTest FULL

  attr_accessor :unpack
  # def unpack?; @unpack; end
  alias_method :unpack?, :unpack
  def initialize(*args)
    # TODO: should probably be Type.unknown
    @sexp_type = Type === args.last ? args.pop : nil
    @unpack = false
    super(args)
  end

  @@array_types = [ :array, :args, ]

  # TODO: need to write test
  def find_and_replace_all(from, to)
    each_with_index do | elem, index |
      if Sexp === elem then
        elem.find_and_replace_all(from, to)
      else
        self[index] = to if elem == from
      end
    end
  end

  def array_type?
    type = self.first
    @@array_types.include? type
  end

  def sexp_type
    unless array_type? then
      @sexp_type
    else
      types = self.sexp_types.flatten.uniq

      if types.size > 1 then
        Type.hetero
      else
        Type.homo
      end
    end
  end

  def sexp_type=(o)
    raise "You shouldn't call this on an #{first}" if array_type?
    @sexp_type = o
  end

  def sexp_types
    raise "You shouldn't call this if not an #{@@array_types.join(' or ')}, was #{first}" unless array_type?
    self.grep(Sexp).map { |x| x.sexp_type }
  end

  def to_a
    result = self.map { |o| Sexp === o ? o.to_a : o }
    unless @sexp_type.nil? then
      result += [ @sexp_type ]
    end
    result
  end

  def ==(obj)
    case obj
    when Sexp
      super && sexp_type == obj.sexp_type
    else
      false
    end
  end

  def inspect
    "Sexp.new(#{self.map {|x|x.inspect}.join(', ')}, #{array_type? ? sexp_types.inspect : sexp_type})"
  end

  def pretty_print(q)
    q.group(1, 'Sexp.new(', ')') do
      q.seplist(self) {|v| q.pp v }
      if @sexp_type then
        q.text ", "
        q.pp @sexp_type
      end
    end
  end

  def to_s
    self.join(" ")
  end

  def shift
    raise "I'm empty" if self.empty?
    super
  end if $DEBUG or $TESTING

end

class SexpProcessor
  
  attr_accessor :default_method
  attr_accessor :warn_on_default
  attr_accessor :auto_shift_type
  attr_accessor :exclude
  attr_accessor :strict
  attr_accessor :debug
  attr_accessor :expected

  def initialize
    @collection = []
    @default_method = nil
    @warn_on_default = true
    @auto_shift_type = false
    @strict = false
    @exclude = []
    @debug = {}
    @expected = Sexp

    # we do this on an instance basis so we can subclass it for
    # different processors.
    @methods = {}

    public_methods.each do |name|
      next unless name =~ /^process_(.*)/
      @methods[$1.intern] = name.intern
    end
  end

  def process(exp)
    return nil if exp.nil?

    exp_orig = exp.deep_clone
    result = Sexp.new

    type = exp.first

    if @debug.include? type then
      str = exp.inspect
      puts "// DEBUG: #{str}" if str =~ @debug[type]
    end
    
    raise SyntaxError, "'#{type}' is not a supported node type." if @exclude.include? type

    meth = @methods[type] || @default_method
    if meth then
      if @warn_on_default and meth == @default_method then
        $stderr.puts "WARNING: falling back to default method #{meth} for #{exp.first}"
      end
      if @auto_shift_type and meth != @default_method then
        exp.shift
      end
      result = self.send(meth, exp)
      raise "Result must be a #{@expected}, was #{result.class}:#{result.inspect}" unless @expected === result
      raise "exp not empty after #{self.class}.#{meth} on #{exp.inspect} from #{exp_orig.inspect}" unless exp.empty?
    else
      unless @strict then
        until exp.empty? do
          sub_exp = exp.shift
          sub_result = nil
          if Array === sub_exp then
            sub_result = process(sub_exp)
            raise "Result is a bad type" unless Array === sub_exp
            raise "Result does not have a type in front: #{sub_exp.inspect}" unless Symbol === sub_exp.first unless sub_exp.empty?
          else
            sub_result = sub_exp
          end
          if Sexp === sub_result && sub_result.unpack? then
            result.push(*sub_result)
          else
            result << sub_result
          end
        end
      else
        raise SyntaxError, "Bug! Unknown type #{type.inspect} to #{self.class}"
      end
    end
    result
  end

  def generate
    raise "not implemented yet"
  end

  def assert_type(list, typ)
    raise TypeError, "Expected type #{typ.inspect} in #{list.inspect}" \
      if list.first != typ
  end

end
