begin require 'rubygems'; rescue LoadError; end
require 'sexp'
require 'type'

$TESTING = false unless defined? $TESTING

class Sexp
  @@array_types = [ :array, :args ]

  alias array_type? array_type? # shuts up duplicate method warning

  ##
  # Returns true if the node_type is +array+ or +args+.

  def array_type?
    type = self.sexp_type
    @@array_types.include? type
  end
end

class TypedSexp < Sexp
  def ==(obj)
    case obj
    when TypedSexp
      super && c_type == obj.c_type
    else
      false
    end
  end

  def new(*stuff)
    r = super
    r.c_type = self.c_type if self.c_type
    r
  end

  def _set_c_type(o)
    @c_type = o
  end

  def initialize(*args)
    # TODO: should probably be CType.unknown
    @c_type = CType === args.last ? args.pop : nil
    super(*args)
  end

  def inspect
    sexp_str = self.map {|x|x.inspect}.join(', ')
    c_type_str = (sexp_str.empty? ? "" : ", ") + "#{array_type? ? c_types.inspect : c_type}" unless c_type.nil?
    nnd = ")"
    nnd += ".line(#{line})" if line && ENV["VERBOSE"]
    "t(#{sexp_str}#{c_type_str}#{nnd}"
  end

  def pretty_print(q)
    nnd = ")"
    nnd << ".line(#{line})" if line && ENV["VERBOSE"]

    q.group(1, 't(', nnd) do
      q.seplist(self) {|v| q.pp v }
      unless @c_type.nil? then
        q.text ", " unless self.empty?
        q.pp @c_type
      end
    end
  end

  def c_type
    unless array_type? then
      defined?(@c_type) && @c_type
    else
      types = self.c_types.flatten.uniq

      if types.size > 1 then
        CType.hetero
      else
        CType.homo
      end
    end
  end

  def c_type=(o)
    # HACK raise "You shouldn't call this on an #{first}" if array_type?
    # c_type is different in ruby2c than from sexp_processor. need renames
    raise "You shouldn't call this a second time, ever" unless
      @c_type.nil? or @c_type == CType.unknown
    _set_c_type(o)
  end

  def c_types
    raise "You shouldn't call this if not an #{@@array_types.join(' or ')}, was #{first} (#{self.inspect})" unless array_type?
    self.grep(Sexp).map { |x| x.c_type }
  end

  def to_a
    result = super
    if defined?(@c_type) and not @c_type.nil? then
      result += [ @c_type ]
    end
    result
  end

  def to_s
    inspect
  end

end

def t(*args) # stupid shortcut to make indentation much cleaner
  TypedSexp.new(*args)
end

