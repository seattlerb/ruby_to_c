
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
      result = self.send(@methods[type], exp)
    else
      exp.each do |x|
        if Array === x then
          result << process(x)
        else
          result << x
        end
      end
    end
    return result
  end

  def generate
    raise "not implemented yet"
  end
end
