
$TESTING = false unless defined? $TESTING

class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

class Sexp < Array # ZenTest FULL

  @@array_types = [ :array, :args, ]

  attr_accessor :accessors
  attr_accessor :unpack

  alias_method :unpack?, :unpack

  def initialize(*args)
    @unpack = false
    @accessors = []
    super(args)
  end

  def array_type?
    type = self.first
    @@array_types.include? type
  end

  def each_of_type(t, &b)
    each do | elem |
      if Sexp === elem then
        elem.each_of_type(t, &b)
        b.call(elem) if elem.first == t
      end
    end
  end

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

  def method_missing(meth, *a, &b)
    super unless @accessors.include? meth

    index = @accessors.index(meth) + 1 # skip type
    return self.at(index)
  end

  def sexp_body
    self[1..-1]
  end

  def ==(obj)
    case obj
    when Sexp
      super
    else
      false
    end
  end

  def to_a
    self.map { |o| Sexp === o ? o.to_a : o }
  end

  def inspect
    sexp_str = self.map {|x|x.inspect}.join(', ')
    return "Sexp.new(#{sexp_str})"
  end

  def pretty_print(q)
    q.group(1, 's(', ')') do
      q.seplist(self) {|v| q.pp v }
    end
  end

  def to_s
    inspect
  end

  def shift
    raise "I'm empty" if self.empty?
    super
  end if $DEBUG and $TESTING

end

def s(*args) # stupid shortcut to make indentation much cleaner
  Sexp.new(*args)
end

##
# SexpProcessor provides a uniform interface to process Sexps.
#
# In order to create your own SexpProcessor subclass you'll need
# to call super in the initialize method, then set any of the
# Sexp flags you want to be different from the defaults.
#
# SexpProcessor uses a Sexp's type to determine which process
# method to call in the subclass.  For Sexp <code>s(:lit,
# 1)</code> SexpProcessor will call #process_lit.
#
# You can also provide a default method to call for any Sexp
# types without a process_ method.
#
# Here is a simple example:
#
#   class MyProcessor < SexpProcessor
#   
#     def initialize
#       super
#       self.strict = false
#     end
#   
#     def process_lit(exp)
#       val = exp.shift
#       return val
#     end
#   
#   end

class SexpProcessor
  
  ##
  # A default method to call if a process_ method is not found
  # for the Sexp type.

  attr_accessor :default_method

  ##
  # Emit a warning when the method in #default_method is called.

  attr_accessor :warn_on_default

  ##
  # Automatically shifts off the Sexp type before handing the
  # Sexp to process_

  attr_accessor :auto_shift_type

  ##
  # A list of Sexp types.  Raises an exception if a Sexp type in
  # this list is encountered.

  attr_accessor :exclude

  ##
  # Raise an exception if no process_ method is found for a Sexp.

  attr_accessor :strict

  ##
  # A Hash of Sexp types and Regexp.
  #
  # Print a debug message if the Sexp type matches the Hash key
  # and the Sexp's #inspect output matches the Regexp.

  attr_accessor :debug

  ##
  # Expected result class

  attr_accessor :expected

  ##
  # Raise an exception if the Sexp is not empty after processing

  attr_accessor :require_empty

  ##
  # Adds accessor methods to the Sexp

  attr_accessor :sexp_accessors

  ##
  # Creates a new SexpProcessor.  Use super to invoke this
  # initializer from SexpProcessor subclasses, then use the
  # attributes above to customize the functionality of the
  # SexpProcessor

  def initialize
    @collection = []
    @default_method = nil
    @warn_on_default = true
    @auto_shift_type = false
    @strict = false
    @exclude = []
    @debug = {}
    @expected = Sexp
    @require_empty = true
    @sexp_accessors = {}

    # we do this on an instance basis so we can subclass it for
    # different processors.
    @methods = {}

    public_methods.each do |name|
      next unless name =~ /^process_(.*)/
      @methods[$1.intern] = name.intern
    end
  end

  ##
  # Default Sexp processor.  Invokes process_ methods matching
  # the Sexp type given.  Performs additional checks as specified
  # by the initializer.

  def process(exp)
    return nil if exp.nil?

    exp_orig = exp.deep_clone if $DEBUG
    result = self.expected.new

    type = exp.first

    if @debug.include? type then
      str = exp.inspect
      puts "// DEBUG: #{str}" if str =~ @debug[type]
    end

    if Sexp === exp then
      if @sexp_accessors.include? type then
        exp.accessors = @sexp_accessors[type]
      else
        exp.accessors = [] # clean out accessor list in case it changed
      end
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
      raise TypeError, "Result must be a #{@expected}, was #{result.class}:#{result.inspect}" unless @expected === result
      if $DEBUG then
        raise "exp not empty after #{self.class}.#{meth} on #{exp.inspect} from #{exp_orig.inspect}" if @require_empty and not exp.empty?
      else
        raise "exp not empty after #{self.class}.#{meth} on #{exp.inspect}" if @require_empty and not exp.empty?
      end
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

        # NOTE: this is costly, but we are in the generic processor
        # so we shouldn't hit it too much with RubyToC stuff at least.
        #if Sexp === exp and not exp.sexp_type.nil? then
        begin
          result.sexp_type = exp.sexp_type
        rescue Exception
          # nothing to do, on purpose
        end
      else
        raise SyntaxError, "Bug! Unknown type #{type.inspect} to #{self.class}"
      end
    end
    result
  end

  def generate # :nodoc:
    raise "not implemented yet"
  end

  ##
  # Raises unless the Sexp type for +list+ matches +typ+

  def assert_type(list, typ)
    raise TypeError, "Expected type #{typ.inspect} in #{list.inspect}" \
      if list.first != typ
  end

end

