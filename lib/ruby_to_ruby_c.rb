
$TESTING = false unless defined? $TESTING

begin require 'rubygems' rescue LoadError end
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
      @translator << R2CRewriter.new
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

  def process_call(exp)
    receiver = process(exp.shift) || "self"
    name = exp.shift.to_s
    arg_count = exp.first.size - 1 rescue 0
    args = [process(exp.shift)].flatten.compact

    # TODO: eric is a big boner
    return "NIL_P(#{receiver})" if name == "nil?"

    name = '===' if name =~ /^case_equal_/ # undo the evils of TypeChecker

    if args.empty?
      args = "0"
    else
      args = "#{arg_count}, #{args.join(", ")}"
    end

    "rb_funcall(#{receiver}, rb_intern(#{name.inspect}), #{args})"
  end

  # TODO: pull process_const from obfuscator
  # TODO: pull process_colon2 from obfuscator
  # TODO: pull process_cvar from obfuscator
  # TODO: pull process_dasgn_curr from obfuscator
  # TODO: pull process_dstr from obfuscator

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

  def process_iter(exp) # TODO/REFACTOR: audit against obfuscator
    out = []
    # Only support enums in C-land
    raise UnsupportedNodeError if exp[0][1].nil? # HACK ugly
    @env.scope do
      enum = exp[0][1][1] # HACK ugly t(:iter, t(:call, lhs <-- get lhs
      call = process exp.shift
      var  = process(exp.shift).intern # semi-HACK-y
      body = process exp.shift
      index = "index_#{var}"

      body += ";" unless body =~ /[;}]\Z/
      body.gsub!(/\n\n+/, "\n")

      out << "unsigned long #{index};"
      out << "unsigned long arrays_max = FIX2LONG(rb_funcall(arrays, rb_intern(\"size\"), 0));"
      out << "for (#{index} = 0; #{index} < arrays_max; ++#{index}) {"
      out << "VALUE x = rb_funcall(arrays, rb_intern(\"at\"), 1, LONG2FIX(index_x));"
      out << body
      out << "}"
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

    exp_type = exp.sexp_type
    @env.add var.to_sym, exp_type
    var_type = self.class.c_type exp_type

    if exp_type.list? then
      assert_type args, :array

      raise "array must be of one type" unless args.sexp_type == Type.homo

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

  # TODO: pull while from obfuscator
  # TODO: pull zsuper from obfuscator
end
