
class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

class SexpProcessor
  
  attr_accessor :default_method
  attr_accessor :warn_on_default
  attr_accessor :auto_shift_type
  attr_accessor :exclude
  attr_accessor :strict
  attr_accessor :debug

  def initialize
    @collection = []
    @default_method = nil
    @warn_on_default = true
    @auto_shift_type = false
    @strict = false
    @exclude = []
    @debug = {}

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
    result = []

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
      raise "exp not empty after #{self.class}.#{meth} on #{exp.inspect} from #{exp_orig.inspect}" unless exp.empty?
    else
      unless @strict then
        until exp.empty? do
          sub_exp = exp.shift
          if Array === sub_exp then
            result << process(sub_exp)
          else
            result << sub_exp
          end
        end
      else
        raise SyntaxError, "Bug! Unknown type #{type.inspect} in #{(exp).inspect}"
      end
    end
    return result
  end

  def generate
    raise "not implemented yet"
  end

  def assert_type(list, typ)
    raise TypeError, "Expected type #{typ.inspect} in #{list.inspect}" \
      if list.first != typ
  end

end
