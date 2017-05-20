$TESTING = false unless defined? $TESTING

begin require 'rubygems'; rescue LoadError; end
require 'ruby_to_ansi_c'

class RubyToRubyC < RubyToAnsiC

  ##
  # Lazy initializer for the composite RubytoC translator chain.

  def self.translator
    # TODO: FIX, but write a test first
    unless defined? @translator then
      @translator = CompositeSexpProcessor.new
      @translator << Rewriter.new
      @translator << TypeChecker.new
      @translator << CRewriter.new
      @translator << RubyToRubyC.new
      @translator.on_error_in(:defn) do |processor, exp, err|
        result = processor.expected.new
        case result
        when Array then
          result << :error
        end
        msg = "// ERROR: #{err.class}: #{err}"
        msg += " in #{exp.inspect}" unless exp.nil? or $TESTING
        msg += " from #{caller.join(', ')}" unless $TESTING
        result << msg
        result
      end
    end
    @translator
  end

  def self.c_type(x)
    "VALUE"
  end

  def initialize
    super

    self.unsupported -= [:dstr, :dxstr, :xstr]

    @c_klass_name = nil
    @current_klass = nil
    @klass_name = nil
    @methods = {}
  end

  def process_call(exp)
    receiver = process(exp.shift) || "self"
    name = exp.shift.to_s
    arg_count = exp.first.size - 1 rescue 0
    args = process(exp.shift) # TODO: we never ever test multiple arguments!

    # TODO: eric is a big boner
    return "NIL_P(#{receiver})" if name == "nil?"

    name = '===' if name =~ /^case_equal_/ # undo the evils of TypeChecker

    if args.empty? || args == "rb_ary_new()" then # HACK
      args = "0"
    else
      args = "#{arg_count}, #{args}"
    end

    "rb_funcall(#{receiver}, rb_intern(#{name.inspect}), #{args})"
  end

  # TODO: pull process_const from obfuscator
  # TODO: pull process_colon2 from obfuscator
  # TODO: pull process_cvar from obfuscator
  # TODO: pull process_dasgn_curr from obfuscator

  ##
  # Function definition

  def process_defn(exp)
    make_function exp
  end

  def process_defx(exp)
    make_function exp, false
  end

  ##
  # String interpolation

  def process_dstr(exp)
    parts = []
    parts << process(s(:str, exp.shift))
    until exp.empty? do
      parts << process(exp.shift)
    end

    pattern = process(s(:str, "%s" * parts.length))
    parts.unshift pattern
                     
    return %{rb_funcall(rb_mKernel, rb_intern("sprintf"), #{parts.length}, #{parts.join(", ")})}
  end

  ##
  # Backtick interpolation.

  def process_dxstr(exp)
    dstr = process_dstr exp
    return "rb_funcall(rb_mKernel, rb_intern(\"`\"), 1, #{dstr})"
  end

  ##
  # False. Pretty straightforward.

  def process_false(exp)
    "Qfalse"
  end

  # TODO: pull up process_gasgn from obfuscator

  ##
  # Global variables, evil but necessary.

  def process_gvar(exp)
    var = exp.shift
    "rb_gv_get(#{var.to_s.inspect})"
  end

  # TODO: pull hash from obfuscator
  # TODO: pull iasgn from obfuscator
  # TODO: pull ivar from obfuscator

  ##
  # Iterators for loops. After rewriter nearly all iter nodes
  # should be able to be interpreted as a for loop. If not, then you
  # are doing something not supported by C in the first place.
  #--
  # TODO have CRewriter handle generating lasgns for statics

  def process_iter(exp)
    call = exp.shift
    args = exp.shift
    block_method = exp.shift

    iterable = process call[1] # t(:call, lhs, :iterable, rhs)

    # t(:args, t(:array, of frees), t(:array, of statics))
    free_arg_exps = args[1]
    static_arg_exps = args[2]
    free_arg_exps.shift # :array
    static_arg_exps.shift # :array

    free_args = free_arg_exps.zip(static_arg_exps).map { |f,s| [process(f), process(s)] }

    out = []

    # save
    out.push(*free_args.map { |free,static| "#{static} = #{free};" })

    out << "rb_iterate(rb_each, #{iterable}, #{block_method}, Qnil);"

    # restore
    free_args.each do |free, static|
      out << "#{free} = #{static};"
      statics << "static VALUE #{static};"
    end

    return out.join("\n")
  end

  ##
  # Assignment to a local variable.
  #
  # TODO: figure out array issues and clean up.

  def process_lasgn(exp) # TODO: audit against obfuscator
    out = ""

    var = exp.shift
    value = exp.shift
    # grab the size of the args, if any, before process converts to a string
    arg_count = 0
    arg_count = value.length - 1 if value.first == :array
    args = value

    exp_type = exp.c_type
    @env.add var.to_sym, exp_type

    if exp_type.list? then
      assert_type args, :array

      raise "array must be of one type" unless args.c_type == CType.homo

      args.shift # :arglist
      # REFACTOR: this (here down) is the only diff w/ super
      out << "#{var} = rb_ary_new2(#{args.length});\n"
      args.each_with_index do |o,i|
        out << "rb_ary_store(#{var}, #{i}, #{process o});\n"
      end
    else
      out << "#{var} = #{process args}"
    end

    out.sub!(/;\n\Z/, '')

    return out
  end

  ##
  # Literals, numbers for the most part. Will probably cause
  # compilation errors if you try to translate bignums and other
  # values that don't have analogs in the C world. Sensing a pattern?

  def process_lit(exp)
    # TODO: audit against obfuscator
    value = exp.shift
    case value
    when Integer then
      return "LONG2NUM(#{value})"
    when Float then
      return "rb_float_new(#{value})"
    when Symbol
      return "ID2SYM(rb_intern(#{value.to_s.inspect}))"
    when Range
      f = process_lit [ value.first ]
      l = process_lit [ value.last ]
      x = 0
      x = 1 if value.exclude_end?

      return "rb_range_new(#{f}, #{l}, #{x})"
    when Regexp
      src = value.source
      return "rb_reg_new(#{src.inspect}, #{src.size}, #{value.options})"
    else
      raise "Bug! no: Unknown literal #{value}:#{value.class}"
    end
    return nil
  end

  # TODO: pull match/2/3 from obfuscator
  # TODO: pull next from obfuscator (and modify for iters)

  # TODO: process_not?!? wtf? I don't think the ansi not works

  ##
  # Nil, currently ruby nil, not C NULL (0).

  def process_nil(exp)
    return "Qnil"
  end

  ##
  # Strings. woot.

  def process_str(exp)
    return "rb_str_new2(#{exp.shift.inspect})"
  end

  ##
  # Truth... what is truth? In this case, Qtrue.

  def process_true(exp)
    "Qtrue"
  end

  ##
  # Backtick.  Maps directly to Kernel#`, no overriding.

  def process_xstr(exp)
    command = exp.shift
    return "rb_funcall(rb_mKernel, rb_intern(\"`\"), 1, rb_str_new2(#{command.inspect}))"
  end

  # TODO: pull while from obfuscator
  # TODO: pull zsuper from obfuscator

  ##
  # Makes a new function from +exp+.  Registers the function in the method
  # list and adds self to the signature when +register+ is true.

  def make_function(exp, register = true)
    name = map_name exp.shift
    args = exp.shift
    ruby_args = args.deep_clone
    ruby_args.shift # :args

    @method_name = name
    @c_method_name = "rrc_c#{@c_klass_name}_#{normal_to_C name}"

    @env.scope do
      c_args = check_args args, register # registered methods get self
      @methods[name] = ruby_args if register

      body = process exp.shift

      if name == :initialize then
        body[-1] = "return self;\n}"
      end

      return "static VALUE\n#{@c_method_name}#{c_args} #{body}"
    end
  end

  ##
  # Checks +args+ for unsupported variable types.  Adds self when +add_self+
  # is true.

  def check_args(args, add_self = true)
    c_args = process args

# HACK
#     c_args.each do |arg|
#       raise UnsupportedNodeError,
#       "'#{arg}' is not a supported variable type" if arg.to_s =~ /^\*/
#     end

    if add_self then
      if c_args == '()' then
        c_args = '(VALUE self)'
      else
        c_args.sub! '(', '(VALUE self, '
      end
    end

    return c_args
  end

  ##
  # HACK merge with normal_to_C (?)

  def map_name(name)
    # HACK: get from zentest
    name = METHOD_MAP[name] if METHOD_MAP.has_key? name
    name.to_s.sub(/(.*)\?$/, 'is_\1').intern
  end

  ##
  # DOC
  # TODO:  get mappings from zentest

  def normal_to_C(name)
    name = name.to_s.dup

    name.sub!(/==$/, '_equals2')
    name.sub!(/=$/, '_equals')
    name.sub!(/\?$/, '_p')
    name.sub!(/\!$/, '_bang')

    return name
  end

end
