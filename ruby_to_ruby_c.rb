
$TESTING = false unless defined? $TESTING

begin require 'rubygems' rescue LoadError end
require 'ruby_to_ansi_c'

class RubyToRubyC < RubyToAnsiC

  ##
  # Lazy initializer for the composite RubytoC translator chain.

  def self.translator
    # TODO: FIX, but write a test first
    unless defined? @@translator then
      @@translator = CompositeSexpProcessor.new
      @@translator << Rewriter.new
      @@translator << TypeChecker.new
      @@translator << R2CRewriter.new
      @@translator << RubyToRubyC.new
      @@translator.on_error_in(:defn) do |processor, exp, err|
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
    @@translator
  end

  ##
  # Assignment to a local variable.
  #
  # TODO: figure out array issues and clean up.

  def process_lasgn(exp)
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

  def self.c_type(x)
    "VALUE"
  end

  def initialize # :nodoc:
    super
  end

  def process_true(exp)
    "Qtrue"
  end

  def process_false(exp)
    "Qfalse"
  end

  ##
  # Iterators for loops. After rewriter nearly all iter nodes
  # should be able to be interpreted as a for loop. If not, then you
  # are doing something not supported by C in the first place.

  def process_iter(exp)
    out = []
    @env.scope do
      enum = exp[0][1][1] # HACK ugly
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
  # Nil, currently ruby nil, not C NULL (0).

  def process_nil(exp)
    return "Qnil"
  end

  def process_gvar(exp)
    var = exp.shift
    "rb_gv_get(#{var.to_s.inspect})"
  end

  def process_lit(exp)
    value = exp.shift

    case value
    when Fixnum then
      "LONG2NUM(#{value})"
    when Float then
      "DBL2NUM(#{value})"
    when Symbol then
      "rb_intern(#{value.to_s.inspect})"
    else
      raise "Bug! no: Unknown literal #{value}:#{value.class}"
    end
  end

  def process_str(exp)
    value = exp.shift
    "rb_str_new2(#{value.inspect})"
  end

  def process_call(exp)
    receiver = process(exp.shift) || "self"
    name = exp.shift.to_s
    args = [process(exp.shift)].flatten.compact

    name = '===' if name =~ /^case_equal_/ # undo the evils of TypeChecker

    if args.empty?
      args = "0"
    else
      args = "#{args.size}, #{args.join(", ")}"
    end

    "rb_funcall(#{receiver}, rb_intern(#{name.inspect}), #{args})"
  end
end
