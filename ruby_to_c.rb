require 'pp'
require 'type_checker'
require 'sexp_processor'
require 'composite_sexp_processor'
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

    base_type += "[]" if typ.list?

    base_type
  end

end

class RubyToC < SexpProcessor

  include TypeMap

  attr_reader :env
  attr_reader :prototypes

  def self.preamble
    "// BEGIN METARUBY PREAMBLE
#include <ruby.h>
#define RB_COMPARE(x, y) (x) == (y) ? 0 : (x) < (y) ? -1 : 1

// END METARUBY PREAMBLE
"
  end

  # REFACTOR: rename to self.process
  def self.translate(klass, method=nil)
    unless defined? @@translator then
      @@translator = CompositeSexpProcessor.new
      @@translator << Rewriter.new
      @@translator << TypeChecker.new
      @@translator << self.new
    end
    @@translator.process(ParseTree.new.parse_tree(klass, method))
  end

  def self.translate_all_of(klass, catch_exceptions=false)
    result = []

    klass.instance_methods(false).sort.each do |method|
      if catch_exceptions then
        begin
          result << self.translate(klass, method)
        rescue RuntimeError => err
          [ "// ERROR translating #{method}: #{err}",
            "//   #{err.backtrace.join("\n//   ")}",
            "//   #{ParseTree.new.parse_tree(klass, method).inspect}" ]
        end
      else
        result << self.translate(klass, method)
      end
    end

    prototypes =  @@translator.processors[-1].prototypes
    "#{prototypes.join('')}\n\n#{result.join("\n\n")}"
  end

  attr_accessor :prototypes
  def initialize
    super
    @env = Environment.new
    self.auto_shift_type = true
    self.exclude = [:case, :when, :rescue, :const, :dstr]
    self.strict = true
    self.expected = String

    @prototypes = []
  end

  def process_args(exp)
    args = []

    until exp.empty? do
      arg = exp.shift
      args << "#{c_type(arg.sexp_type)} #{arg}"
    end

    return "(#{args.join ', '})"
  end

  def process_array(exp)
    code = []

    until exp.empty? do
      code << process(exp.shift) 
    end

    return "#{code.join ', '}"
  end

  def process_block(exp)
    code = []
    until exp.empty? do
      code << process(exp.shift)
    end

    body = code.join(";\n")
    body += ";" unless body =~ /[;}]\Z/
    body += "\n"

    return body
  end

  def process_call(exp)
    name = exp.shift
    receiver = process exp.shift
    args = process exp.shift

    case name
    when "==", "<", ">", "<=", ">=", # TODO: these need to be numerics
         "-", "+", "*", "/", "%" then
      return "#{receiver} #{name} #{args}"
    when "<=>"
      return "RB_COMPARE(#{receiver}, #{args})"
    when "equal?"
      return "#{receiver} == #{args}" # equal? == address equality
    else
      name = "NIL_P" if name == "nil?"

      if receiver.nil? and args.nil? then
        args = ""
      elsif receiver.nil? then
        # nothing to do 
      elsif args.nil? then
        args = receiver
      else
        args = "#{receiver}, #{args}"
      end

      return "#{name}(#{args})"
    end
  end

  def process_dasgn_curr(exp)
    var = exp.shift
    @env.add var, exp.sexp_type
    return var
  end

  def process_defn(exp)

    name = exp.shift
    args = process exp.shift
    body = process exp.shift
    function_type = exp.sexp_type

    ret_type = c_type function_type.list_type.return_type

    @prototypes << "#{ret_type} #{name}#{args};\n"
    "#{ret_type}\n#{name}#{args} #{body}"
  end

  def process_dvar(exp)
    var = exp.shift
    @env.add var, exp.sexp_type
    return var
  end

  def process_false(exp)
    return "Qfalse"
  end

  def process_gvar(exp)
    name = exp.shift
    type = exp.sexp_type
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

  def process_iter(exp) # TODO add ;\n as appropriate
    @env.extend

#    p exp

    enum = exp[0][2][1] # HACK ugly
    call = process exp.shift
    var = process exp.shift
    body = process exp.shift
    index = "index_#{var}"

    body += ";" unless body =~ /[;}]\Z/

    out =  "unsigned long #{index};\n"
    out << "for (#{index} = 0; #{index} < #{enum}.length; ++#{index}) {\n"
    out << "#{c_type @env.lookup(var)} #{var} = #{enum}.contents[#{index}];\n"
    out << body
    out << "\n" unless out =~ /[\n]\Z/
    out << "}"

    @env.unextend
    return out
  end

  def process_lasgn(exp)
    out = ""

    var = exp.shift
    value = exp.shift
    # grab the size of the args, if any, before process converts to a string
    arg_count = 0
    arg_count = value.length - 1 if value.first == :array
    args = process value

    var_type = exp.sexp_type
    @env.add var, var_type
    var_type = c_type var_type

    if var_type =~ /\[\]$/ then
      out << "#{var}.contents = { #{args} };\n"
      out << "#{var}.length = #{arg_count}"
    else
      out << "#{var} = #{args}"
    end

    return out
  end

  def process_lit(exp)
    return exp.shift.to_s # TODO what about floats and big numbers?
  end

  def process_lvar(exp)
    name = exp.shift
    # HACK: wtf??? there is no code! do nothing? if so, comment that!
    return name
  end

  def process_nil(exp)
    return "Qnil"
  end

  def process_or(exp)
    lhs = process exp.shift
    rhs = process exp.shift

    return "#{lhs} || #{rhs}"
  end

  def process_return(exp)
    return "return #{process exp.shift}"
  end

  def process_scope(exp)
    @env.extend
    body = process exp.shift unless exp.empty?
    declarations = []
    @env.current.sort_by { |v,t| v }.each do |var, var_type|
      var_type = c_type var_type
      if var_type =~ /(.*)(?: \*)?\[\]/ then
        declarations << "#{$1}_array #{var};\n"
      else
        declarations << "#{var_type} #{var};\n"
      end
    end

    @env.unextend
    return "{\n#{declarations}#{body}}"
  end

  def process_str(exp)
    return "\"#{exp.shift}\""
  end

  def process_true(exp)
    return "Qtrue"
  end

  def process_while(exp)
    cond = process exp.shift
    body = process exp.shift
    return "while (#{cond}) {\n#{body.strip}\n}"
  end

end

