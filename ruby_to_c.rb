require 'infer_types'
require 'sexp_processor'
require 'rewriter'

module TypeMap

  def c_type(typ)
    base_type = 
      case typ.type.contents # HACK this is breaking demeter
      when :long then
        "long"
      when :str then
        "char *"
      when :bool then # TODO: subject to change
        "long"
      when :void then
        "void"
      when :value, :unknown then
        "VALUE"
# HACK: uncomment this and fix the above when you want to have good tests
#      when :unknown then
#        raise "You should not have unknown types by now!"
      else
        raise "Bug! Unknown type #{typ.inspect}"
      end

    base_type += "[]" if typ.list? # HACK - nuke me - and figure out why

    base_type
  end

end

class RubyToC < SexpProcessor

  include TypeMap

  attr_reader :env

  def self.preamble
    "#include <ruby.h>"
  end

  def self.translate(klass, method = nil)
    checker = self.new
    sexp = InferTypes.new.augment(klass, method)
    sexp = Rewriter.new.process(sexp)
    checker.process(sexp)
  end

  def self.translate_all_of(klass, catch_exceptions=false)
    klass.instance_methods(false).sort.map do |method|
      if catch_exceptions then
        begin
          translate(klass, method)
        rescue RuntimeError => err
          [ "// ERROR translating #{method}: #{err}",
            "//   #{err.backtrace.join("\n//   ")}",
            "//   #{ParseTree.new.parse_tree(klass, method).inspect}" ]
        end
      else
        translate(klass, method)
      end
    end.join "\n\n"
  end

  def initialize
    super
    self.auto_shift_type = true
    self.default_method = :translate
    self.exclude = [:case, :when, :rescue, :const, :dstr]
    self.strict = true
  end

  def process_args(exp)
    unless exp.empty? then
      args = []
      until exp.empty? do
        arg, typ = exp.shift
        args << "#{c_type(typ)} #{arg}"
      end
      args.join ', '
    else
      ""
    end
  end

  def process_array(exp)
    code = []
    until exp.empty? do
      code << process(exp.shift)
    end
    code
  end

  def process_block(exp)
    code = []
    until exp.empty? do
      thingy = exp.shift
      result = process(thingy)
      code << result
    end
    args = code.shift
    body = code.join(";\n")
    body += ";" unless body =~ /[;}]\Z/
    body += "\n"
    [args, body]
  end

  def process_call(exp)
    lvar = process exp.shift
    method = exp.shift
    unless exp.empty? then
      rvar = process exp.shift
      case method
      when '==', 'equal?',
        '<', '>', '<=', '>=',
        '+', '-', '*', '/', '%' then
        method = "==" if method == 'equal?'
        "#{lvar} #{method} #{rvar.shift}"
      when "<=>" then
        "#{lvar} != #{rvar.shift}"
      when "puts"
        "fputs(#{rvar}, #{lvar})"
      else
        raise "Bug! Unhandled method #{method}"
      end
    else
      case method
      when "each" then
        # iter needs to know the lvar and the method being called
        [lvar, method]
      when "nil?" then
        "NIL_P(#{lvar})"
      when "to_i" then
        "#{lvar}"
      when "to_s" then
        "HACK"
      when "class" then
        "HACK"
      else
        raise "Bug! Unhandled method #{method}"
      end
    end
  end

  def process_dasgn_curr(exp)
    var = exp.shift
    arg = var.shift
    typ = c_type var.shift
    [typ, arg]
  end

  def process_defn(exp)
    name = exp.shift
    args, body = process exp.shift
    ret_type = c_type exp.shift
    "#{ret_type}\n#{name}(#{args}) {#{body}}"
  end

  def process_dvar(exp)
    exp.shift
  end

  def process_false(exp)
    "0"
  end

  def process_fcall(exp)
    name = exp.shift
    args = process exp.shift
    args = args.join ', '
    "#{name}(#{args})"
  end

  def process_gvar(exp)
    name = exp.shift
    type = exp.shift
    case name
    when "$stderr" then
      "stderr"
    else
      raise "Bug! Unhandled gvar #{name} (type = #{type})"
    end
  end

  def process_if(exp)
    cond_part = process exp.shift

    result = "if (#{cond_part})"

    then_block = ! exp.first.nil? && exp.first.first == :block
    then_part  = process exp.shift
    else_block = ! exp.first.nil? && exp.first.first == :block
    else_part  = process exp.shift

    then_part = "" if then_part.nil?
    else_part = "" if else_part.nil?

    result += " {\n"
    
    # HACK: rewrite blocks you stupid fucker
    then_part = then_part.join(";\n") if Array === then_part
    then_part += ";" unless then_part =~ /[;}]\Z/
    # HACK: um... deal with nil correctly (see unless support)
    result += then_part.to_s # + ";"
    result += ";" if then_part.nil?
    result += "\n" unless result =~ /\n\Z/
    result += "}"

    if else_part != "" then
      result += " else {\n"
      else_part = else_part.join(";\n") if Array === else_part
      else_part += ";" unless else_part =~ /[;}]\Z/
      result += else_part
      result += "\n}"
    end

    result
  end

  def process_iter(exp)
    iter, method = process exp.shift
    arg_type, arg_name = process exp.shift
    body_part = process exp.shift
    body_part = body_part.join(";\n") if Array === body_part
    body_part += ";" unless body_part =~ /[;}]\Z/
    index = "index_#{arg_name}"
    res = ""
    res << "unsigned long #{index};\n"
    res << "for (#{index} = 0; #{index} < #{iter}.length; ++#{index}) {\n"
    res << "#{arg_type} #{arg_name} = #{iter}.contents[#{index}];\n"
    res << body_part
    res << "\n" unless res =~ /[\n]\Z/
    res << "}"
    res
  end

  def process_lasgn(exp)
    typ = exp.pop
    unless typ.nil? then
      typ = c_type typ
    end
    name = exp.shift
    args = []
    until exp.empty? do
      sub_exp = exp.shift
      args << process(sub_exp)
    end
    args = args.shift # arg list is enclosed by array [[arg1, arg2]]
    res = ""
    if typ.nil? then
      res << "#{name} = #{args}"
    elsif typ =~ /(.*)\[\]/ then
      res << "#{$1}_array #{name};\n"
      res << "#{name}.contents = { #{args.join ', '} };\n"
      res << "#{name}.length = #{args.length}"
    else
      res << "#{typ} #{name} = #{args}"
    end
    res
  end

  def process_lit(exp)
    exp.shift.to_s
  end

  def process_lvar(exp)
    exp.shift
  end

  def process_nil(exp)
    "Qnil"
  end

  def process_or(exp)
    exps = []
    until exp.empty? do
      exps << process(exp.shift)
    end
    exps.join(" || ")
  end

  def process_return(exp)
    "return #{process exp.shift}"
  end

  def process_scope(exp)
    args, body = process exp.shift
    if body.nil? or body.empty? then
      body = "\n"
    else
      body = "\n#{body}"
    end
    [args, body]
  end

  def process_str(exp)
    "\"#{exp.shift}\""
  end

  def process_true(exp)
    "1"
  end

end

