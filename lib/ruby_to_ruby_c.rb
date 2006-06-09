
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

  def initialize
    super

    self.unsupported -= [:dstr, :xstr]

    @blocks = []
    @c_klass_name = nil
    @current_klass = nil
    @klass_name = nil
    @methods = {}
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
  # TODO: use dstr to implement dxstr

  ##
  # Function definition

  def process_defn(exp)
    name = exp.shift
    # HACK: get from zentest
    name = METHOD_MAP[name] if METHOD_MAP.has_key? name
    name = name.to_s.sub(/(.*)\?$/, 'is_\1').intern
    args = exp.shift
    ruby_args = args.deep_clone
    ruby_args.shift # :args

    @method_name = name
    @c_method_name = "rrc_c#{@c_klass_name}_#{normal_to_C name}"

    @env.scope do
      c_args = process args
      c_args.each do |arg|
        raise UnsupportedNodeError,
        "'#{arg}' is not a supported variable type" if arg.to_s =~ /^\*/
      end

      @methods[name] = ruby_args
      body = process exp.shift
      if name == :initialize then
        body[-1] = "return self;\n}"
      end

      c_args == '()' ? c_args = '(VALUE self)' : c_args.sub!('(', '(VALUE self, ')

      return "static VALUE\n#{@c_method_name}#{c_args} #{body}"
    end
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

  def process_OLD_iter(exp) # TODO/REFACTOR: audit against obfuscator
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
  # Iterators for loops. After rewriter nearly all iter nodes
  # should be able to be interpreted as a for loop. If not, then you
  # are doing something not supported by C in the first place.

  def process_iter(exp)
    # TODO/REFACTOR: this needs severe cleaning
    out = []
    @env.scope do
      enum_name = Unique.next
      enum = process exp[0][1].deep_clone
      call_name = exp.first[-2]
      call = process exp.shift # FIX: I'm not sure why we bother processing this
      args = exp.shift # HACK process(exp.shift).intern

      # this prevents iterator lvar decl in externed function
      @env.add args[1], Type.value if call_name == :map and args.first == :dasgn_curr # HACK don't re-declare variable

      declarations, body = with_scope do
        case args.first
        when :dasgn_curr then
          @env.add args[1], Type.value
        when :masgn then
          args[1][1..-1].each do |ignore,arg|
            @env.add arg, Type.value
          end
        else
          raise "unknown iterator args type #{args.inspect}"
        end if call_name == :each

        process exp.shift # iter body
      end

      case call_name
      when :map then
        # DOC : block iterators MUST have the value explicitly at the end of the block
        # create a temp function using Unique
        func_name = "#{@c_method_name}_#{Unique.next}"
        result_name = Unique.next
        ary_name = Unique.next
        tmp_name = Unique.next

        @env.add result_name, Type.value, 1
        @env.set_val result_name, 'rb_ary_new()'
        out << "rb_iterate(rb_each, #{enum}, #{func_name}, #{result_name})"

        # TODO: look at rewriting this using sexps and process.
        # passing in self will allow for access to local ivars and the like
        # and we won't have as much duplicate code, we just make a defn
        # (and mark it private?)

        new_func = []

        case args.first
        when :dasgn_curr then
          var = process(args).intern
          new_func << "static VALUE #{func_name}(VALUE #{var}, VALUE #{ary_name}) {"
          new_func << "VALUE #{tmp_name};"
          new_func.push(*declarations)
        when :masgn then
          args_ary = Unique.next
          var = Unique.next

          new_func << "static VALUE #{func_name}(VALUE #{var}, VALUE #{ary_name}) {"
          new_func << "VALUE #{tmp_name};"
          new_func.push(*declarations)

          # [:masgn, [:array, [:dasign_curr, :a], ...]]
          args = args[1][1..-1]
          args.each_with_index do |pair, i|
            arg = pair.last
            new_func << "VALUE #{arg} = rb_funcall(#{var}, rb_intern(\"at\"), 1, LONG2FIX(#{i}));"
          end
        else
          raise "unknown iterator args type #{args.inspect}"
        end

        body = body.sub(/\A;\s*/, '').split(/\n/) # blatent hack to deal with stupid obfuscator bug from dasgn_curr
        body[-1] = "#{tmp_name} = #{body[-1]}"
        body[-1] += ';' unless body[-1] =~ /;\Z/
        new_func << body

        new_func << "rb_ary_push(#{ary_name}, #{tmp_name});"
        new_func << "return Qnil;"
        new_func << "}"
        @blocks << new_func.flatten.compact.join("\n")
      when :each then
        # TODO: nuke for loop for above solution
        index = "index_#{enum_name}"

        body += ";" unless body =~ /[;}]\Z/
        body.gsub!(/\n\n+/, "\n")

        ary_var = Unique.next

        out << "unsigned long #{index};"
        out << "VALUE #{ary_var} = rb_funcall(#{enum}, rb_intern(\"to_a\"), 0);"
        out << "unsigned long #{enum_name}_max = FIX2LONG(rb_funcall(#{ary_var}, rb_intern(\"size\"), 0));"
        out << "for (#{index} = 0; #{index} < #{enum_name}_max; ++#{index}) {"
        out.push(*declarations)

        # REFACTOR
        case args.first
        when :dasgn_curr then
          var = process(args).intern
          out << "#{var} = rb_funcall(#{ary_var}, rb_intern(\"at\"), 1, LONG2FIX(#{index}));"
        when :masgn then
          args_ary = Unique.next
          out << "VALUE #{args_ary} = rb_funcall(#{ary_var}, rb_intern(\"at\"), 1, LONG2FIX(#{index}));"
          # [:masgn, [:array, [:dasign_curr, :a], ...]]
          args = args[1][1..-1]
          args.each_with_index do |(ignore,arg),i|
            out << "#{arg} = rb_funcall(#{args_ary}, rb_intern(\"at\"), 1, LONG2FIX(#{i}));"
          end
        else
          raise "unknown iterator args type #{args.inspect}"
        end

        out << body
        out << "}"
      when :loop then
        raise UnsupportedNodeError, "we don't do loop yet"
      else
        raise "unknown iter type #{call_name}"
      end
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

  ##
  # Backtick.  Maps directly to Kernel#`, no overriding.

  def process_xstr(exp)
    command = exp.shift
    return "rb_f_backquote(rb_str_new2(#{command.inspect}))"
  end

  # TODO: pull while from obfuscator
  # TODO: pull zsuper from obfuscator

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
