
class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

class SexpProcessor
  
  attr_accessor :default_method
  attr_accessor :warn_on_default

  def initialize
    @collection = []
    @default_method = nil
    @warn_on_default = true
    # we do this on an instance basis so we can subclass it for
    # different processors.
    @methods = {}
    @auto_shift_type = false
    public_methods.each do |name|
      next unless name =~ /^process_(.*)/
      @methods[$1.intern] = name.intern
    end
  end

  def process(exp)
    exp_orig = exp.deep_clone
    result = []
    return nil if exp.nil?
    type = exp.first
    meth = @methods[type] || @default_method
    if meth then
      if @warn_on_default and meth == @default_method then
        $stderr.puts "WARNING: falling back to default method #{meth}"
      end
      exp.shift if @auto_shift_type
      result = self.send(meth, exp)
      raise "exp not empty after #{self.class}.#{meth} on #{exp.inspect} from #{exp_orig.inspect}" unless exp.empty?
    else
      until exp.empty? do
        sub_exp = exp.shift
        if Array === sub_exp then
          result << process(sub_exp)
        else
          result << sub_exp
        end
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
