
$TESTING = false unless defined? $TESTING

begin
  require 'rubygems'
  require_gem 'ParseTree'
  require 'sexp_processor'
  require 'composite_sexp_processor'
rescue LoadError
  require 'parse_tree'
  require 'sexp_processor'
  require 'composite_sexp_processor'
end

require 'type_checker'
require 'rewriter'
require 'pp'

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
      when :homo then
        "void *" # HACK
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

  module_function :c_type if $TESTING

end

class RubyToC < SexpProcessor

  include TypeMap

  attr_reader :env
  attr_reader :prototypes

  def self.preamble
    "// BEGIN METARUBY PREAMBLE
#include <ruby.h>
#define RB_COMPARE(x, y) (x) == (y) ? 0 : (x) < (y) ? -1 : 1
typedef struct { unsigned long length; long * contents; } long_array;
#define case_equal_long(x, y) ((x) == (y))
// END METARUBY PREAMBLE
"
  end

  def self.translator
    unless defined? @@translator then
      @@translator = CompositeSexpProcessor.new
      @@translator << Rewriter.new
      @@translator << TypeChecker.new
      @@translator << R2CRewriter.new
      @@translator << self.new
    end
    @@translator
  end

  # REFACTOR: rename to self.process
  def self.translate(klass, method=nil)
    unless method.nil? then
      self.translator.process(ParseTree.new.parse_tree_for_method(klass, method))
    else
      self.translator.process(ParseTree.new.parse_tree(klass))
    end
  end

  def self.translate_all_of(klass, catch_exceptions=false)
    result = []

    klass.instance_methods(false).sort.each do |method|
      result << 
        if catch_exceptions then
          begin
            self.translate(klass, method)
          rescue Exception => err
            [ "// ERROR translating #{method}: #{err}",
            "//   #{err.backtrace.join("\n//   ")}",
            "//   #{ParseTree.new.parse_tree_for_method(klass, method).inspect}" ]
          end
        else
          self.translate(klass, method)
        end
    end

    prototypes =  self.translator.processors[-1].prototypes
    "#{prototypes.join('')}\n\n#{result.join("\n\n")}"
  end

  # attr_accessor :prototypes # TODO is this needed anymore?

  def initialize
    super
    @env = Environment.new
    self.auto_shift_type = true
    self.unsupported = [:case, :when, :rescue, :const, :dstr]
    self.strict = true
    self.expected = String

    @prototypes = []
  end

  def process_and(exp)
    lhs = process exp.shift
    rhs = process exp.shift

    return "#{lhs} && #{rhs}"
  end

  def process_args(exp)
    args = []

    until exp.empty? do
      arg = exp.shift
      args << "#{c_type(arg.sexp_type)} #{arg.first}"
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
    receiver = exp.shift
    name = exp.shift
    args = process exp.shift

    receiver_type = Type.unknown
    unless receiver.nil? then
      receiver_type = receiver.sexp_type
    end
    receiver = process receiver

    case name
    when :==, :<, :>, :<=, :>=, # TODO: these need to be numerics
         :-, :+, :*, :/, :% then
      return "#{receiver} #{name} #{args}"
    when :<=>
      return "RB_COMPARE(#{receiver}, #{args})"
    when :equal?
      return "#{receiver} == #{args}" # equal? == address equality
    when :[]
      if receiver_type.list? then
        return "#{receiver}.contents[#{args}]"
      else
        # FIX: not sure about this one... hope for the best.
        return "#{receiver}[#{args}]"
      end
    else
      name = "NIL_P" if name == :nil?

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
    @env.add var.to_sym, exp.sexp_type
    return var.to_s
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
    @env.add var.to_sym, exp.sexp_type
    return var.to_s
  end

  def process_false(exp)
    return "Qfalse"
  end

  def process_gvar(exp)
    name = exp.shift
    type = exp.sexp_type
    case name
    when :$stderr then
      "stderr"
    else
      raise "Bug! Unhandled gvar #{name.inspect} (type = #{type})"
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
      out << "for (#{index} = 0; #{index} < #{enum}.length; ++#{index}) {"
      out << "#{c_type @env.lookup(var)} #{var} = #{enum}.contents[#{index}];"
      out << body
      out << "}"
    end

    return out.join("\n")
  end

  def process_lasgn(exp)
    out = ""

    var = exp.shift
    value = exp.shift
    # grab the size of the args, if any, before process converts to a string
    arg_count = 0
    arg_count = value.length - 1 if value.first == :array
    args = value

    var_type = exp.sexp_type
    @env.add var.to_sym, var_type
    var_type = c_type var_type

    if var_type =~ /\[\]$/ then
      assert_type args, :array
      args.shift
      out << "#{var}.length = #{arg_count};\n"
      out << "#{var}.contents = (long*) malloc(sizeof(long) * #{var}.length);\n"
      args.each_with_index do |o,i|
        out << "#{var}.contents[#{i}] = #{process o};\n"
      end
    else
      out << "#{var} = #{process args}"
    end

    out.sub!(/;\n\Z/, '')

    return out
  end

  def process_lit(exp)
    return exp.shift.to_s # TODO what about floats and big numbers?
  end

  def process_lvar(exp)
    name = exp.shift
    # HACK: wtf??? there is no code! do nothing? if so, comment that!
    return name.to_s
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
    declarations = []
    body = nil
    @env.scope do
      body = process exp.shift unless exp.empty?
      @env.current.sort_by { |v,t| v.to_s }.each do |var, var_type|
        var_type = c_type var_type
        if var_type =~ /(.*)(?: \*)?\[\]/ then # TODO: readability
          declarations << "#{$1}_array #{var};\n"
        else
          declarations << "#{var_type} #{var};\n"
        end
      end
    end
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

  def process_dummy(exp)
    process_block(exp).chomp
  end

end

