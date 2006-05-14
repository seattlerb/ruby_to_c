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
