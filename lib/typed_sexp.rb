
begin require 'rubygems' rescue LoadError end
require 'sexp'
require 'support'

$TESTING = false unless defined? $TESTING

class TypedSexp < Sexp

  def ==(obj)
    case obj
    when TypedSexp
      super && sexp_type == obj.sexp_type
    else
      false
    end
  end

  def _set_sexp_type(o)
    @sexp_type = o
  end

  def initialize(*args)
    # TODO: should probably be Type.unknown
    @sexp_type = Type === args.last ? args.pop : nil
    super(*args)
  end

  def inspect
    sexp_str = self.map {|x|x.inspect}.join(', ')
    sexp_type_str = (sexp_str.empty? ? "" : ", ") + "#{array_type? ? sexp_types.inspect : sexp_type}" unless sexp_type.nil?
    return "t(#{sexp_str}#{sexp_type_str})"
  end

  def pretty_print(q)
    q.group(1, 't(', ')') do
      q.seplist(self) {|v| q.pp v }
      unless @sexp_type.nil? then
        q.text ", " unless self.empty?
        q.pp @sexp_type
      end
    end
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
    raise "You shouldn't call this a second time, ever" unless
      @sexp_type.nil? or @sexp_type == Type.unknown
    _set_sexp_type(o)
  end

  def sexp_types
    raise "You shouldn't call this if not an #{@@array_types.join(' or ')}, was #{first} (#{self.inspect})" unless array_type?
    self.grep(Sexp).map { |x| x.sexp_type }
  end

  def to_a
    result = super
    if defined?(@sexp_type) and not @sexp_type.nil? then
      result += [ @sexp_type ]
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

