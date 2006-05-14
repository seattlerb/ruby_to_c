
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
