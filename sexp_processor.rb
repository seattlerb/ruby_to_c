
class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

class SexpProcessor
  
  def initialize
    @collection = []
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
    result = []
    return nil if exp.nil?
    type = exp.first
    if @methods[type] then
      exp.shift if @auto_shift_type
      result = self.send(@methods[type], exp)
      raise "exp not empty on #{type}: #{exp.inspect}" unless exp.empty?
    else
      exp.each do |sub_exp|
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

  def assert_type(x, l)
    raise TypeError, "Expected type #{x.inspect} in #{l.inspect}" \
      if l.first != x
  end

end
