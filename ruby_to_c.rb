
$TESTING = false unless defined? $TESTING

begin require 'rubygems' rescue LoadError end
require 'parse_tree'
require 'sexp_processor'
require 'composite_sexp_processor'
require 'type_checker'
require 'rewriter'
require 'pp'

##
# Maps a sexp type to a C counterpart.

module TypeMap

  ##
  # Returns a textual version of a C type that corresponds to a sexp
  # type.

  def c_type(typ)
    base_type = 
      case typ.type.contents # HACK this is breaking demeter
      when :float then
     	"double"
      when :long then
        "long"
      when :str then
        "str"
      when :symbol then
        "symbol"
      when :bool then # TODO: subject to change
        "VALUE"
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
        raise "Bug! Unknown type #{typ.inspect} in c_type"
      end

    base_type += "_array" if typ.list?

    base_type
  end

  module_function :c_type # if $TESTING

end

##
# The whole point of this project! RubyToC is an actually very simple
# SexpProcessor that does the final conversion from Sexp to C code.
# This class has more unsupported nodes than any other (on
# purpose--we'd like TypeChecker and friends to be as generally useful
# as possible), and as a result, supports a very small subset of ruby.
#
# NOT SUPPORTED: (keep in sync w/ initialize)
# 
# :begin, :block_arg, :case, :dstr, :rescue, :self, :super, :when

class RubyToC < SexpProcessor

  VERSION = '1.0.0-beta3'

  # TODO: remove me
  def no(exp) # :nodoc:
    raise "no: #{caller[0].split[1]} #{exp.inspect}"
  end

  include TypeMap

  ##
  # Provides access to the variable scope.

  attr_reader :env

  ##
  # Provides access to the method signature prototypes that are needed
  # at the top of the C file.

  attr_reader :prototypes

  ##
  # Provides a (rather bogus) preamble. Put your includes and defines
  # here. It really should be made to be much more clean and
  # extendable.

  def preamble
    "// BEGIN METARUBY PREAMBLE
#include <ruby.h>
#define RB_COMPARE(x, y) (x) == (y) ? 0 : (x) < (y) ? -1 : 1
typedef char * str;
typedef struct { unsigned long length; long * contents; } long_array;
typedef struct { unsigned long length; str * contents; } str_array;
#define case_equal_long(x, y) ((x) == (y))
// END METARUBY PREAMBLE
" + self.prototypes.join('')
  end

  ##
  # Lazy initializer for the composite RubytoC translator chain.

  def self.translator
    unless defined? @@translator then
      @@translator = CompositeSexpProcessor.new
      @@translator << Rewriter.new
      @@translator << TypeChecker.new
      @@translator << R2CRewriter.new
      @@translator << RubyToC.new
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
  # Front-end utility method for translating an entire class or a
  # specific method from that class.

  def self.translate(klass, method=nil)
    # REFACTOR: rename to self.process
    unless method.nil? then
      self.translator.process(ParseTree.new(false).parse_tree_for_method(klass, method))
    else
      ParseTree.new.parse_tree(klass).map do |k|
        self.translator.process(ParseTree.new.parse_tree(klass))
      end
    end
  end

  ##
  # (Primary) Front-end utility method for translating an entire
  # class. Has special error handlers that convert errors into C++
  # comments (//...).

  def self.translate_all_of(klass)
    result = []

    # HACK: make CompositeSexpProcessor have a registered error handler
    klass.instance_methods(false).sort.each do |method|
      result << 
        begin
          self.translate(klass, method)
        rescue UnsupportedNodeError => err
          "// NOTE: #{err} in #{klass}##{method}"
        rescue UnknownNodeError => err
          "// ERROR: #{err} in #{klass}##{method}: #{ParseTree.new.parse_tree_for_method(klass, method).inspect}"
        rescue Exception => err
          "// ERROR: #{err} in #{klass}##{method}: #{ParseTree.new.parse_tree_for_method(klass, method).inspect} #{err.backtrace.join(', ')}"
        end
    end

    prototypes =  self.translator.processors[-1].prototypes
    "#{prototypes.join('')}\n\n#{result.join("\n\n")}"
  end

  def initialize # :nodoc:
    super
    @env = Environment.new
    self.auto_shift_type = true
    self.unsupported = [ :begin, :block_arg, :case, :dstr, :rescue, :self, :super, :when, ]
    self.strict = true
    self.expected = String

    @prototypes = []
  end

  ##
  # Logical And. Nothing exciting here

  def process_and(exp)
    lhs = process exp.shift
    rhs = process exp.shift

    return "#{lhs} && #{rhs}"
  end

  ##
  # Argument List including variable types.

  def process_args(exp)
    args = []

    until exp.empty? do
      arg = exp.shift

#       p arg
#       p arg.sexp_type
#       p arg.first
#       p self.class
#       p arg.sexp_type.class
#       p TypeMap.methods.sort
#       p c_type(arg.sexp_type)

      args << "#{c_type(arg.sexp_type)} #{arg.first}"
    end

    return "(#{args.join ', '})"
  end

  ##
  # Arglist is used by call arg lists.

  def process_arglist(exp)
		return process_array(exp)
  end

  ##
  # Array is used as call arg lists and as initializers for variables.

  def process_array(exp)
    code = []

    until exp.empty? do
      code << process(exp.shift) 
    end

    s = code.join ', '
    s = "[]" if s.empty?

    return s
  end

  ##
  # Block doesn't have an analog in C, except maybe as a functions's
  # outer braces.

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

  ##
  # Call, both unary and binary operators and regular function calls.
  #
  # TODO: This needs a lot of work. We've cheated with the case
  # statement below. We need a real function signature lookup like we
  # have in R2CRewriter.

  def process_call(exp)
    receiver = exp.shift
    name = exp.shift

    receiver_type = Type.unknown
    unless receiver.nil? then
      receiver_type = receiver.sexp_type
    end
    receiver = process receiver

    case name
      # TODO: these need to be numerics
      # emacs gets confused by :/ below, need quotes to fix indentation
    when :==, :<, :>, :<=, :>=, :-, :+, :*, :"/", :% then
      args = process exp.shift[1]
      return "#{receiver} #{name} #{args}"
    when :<=>
      args = process exp.shift[1]
      return "RB_COMPARE(#{receiver}, #{args})"
    when :equal?
      args = process exp.shift
      return "#{receiver} == #{args}" # equal? == address equality
    when :[]
      if receiver_type.list? then
        args = process exp.shift
        return "#{receiver}.contents[#{args}]"
      else
        # FIX: not sure about this one... hope for the best.
        args = process exp.shift
        return "#{receiver}[#{args}]"
      end
    else
      args = process exp.shift
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

  ##
  # DOC

  def process_class(exp)
    name = exp.shift
    superklass = exp.shift

    result = []

    result << "// class #{name}"

    until exp.empty? do
      # HACK: cheating!
      klass = name
      method = exp[1]
      result << process(exp.shift)
    end

    return result.join("\n\n")
  end

  def process_const(exp)
    name = exp.shift
    return name.to_s
  end

  ##
  # Constants, must be defined in the global env.
  #
  # TODO: This will cause a lot of errors with the built in classes
  # until we add them to the bootstrap phase.
  # HACK: what is going on here??? We have NO tests for this node

  def process_cvar(exp)
    # TODO: we should treat these as globals and have them in the top scope
    name = exp.shift
    return name.to_s
  end

  ##
  # Iterator variables.
  # 
  # TODO: check to see if this is the least bit relevant anymore. We
  # might have rewritten them all.

  def process_dasgn_curr(exp)
    var = exp.shift
    @env.add var.to_sym, exp.sexp_type
    return var.to_s
  end

  ##
  # Function definition

  def process_defn(exp)

    name = exp.shift
    args = process exp.shift
    body = process exp.shift
    function_type = exp.sexp_type

    ret_type = c_type function_type.list_type.return_type

    @prototypes << "#{ret_type} #{name}#{args};\n"
    "#{ret_type}\n#{name}#{args} #{body}"
  end

  ##
  # Generic handler. Ignore me, I'm not here.
  #
  # TODO: nuke dummy nodes by using new SexpProcessor rewrite rules.

  def process_dummy(exp)
    process_block(exp).chomp
  end

  ##
  # Dynamic variables, should be the same as lvar at this stage.
  #
  # TODO: remove / rewrite?

  def process_dvar(exp)
    var = exp.shift
    @env.add var.to_sym, exp.sexp_type
    return var.to_s
  end

  ##
  # DOC

  def process_error(exp)
    return exp.shift
  end

  ##
  # False. Pretty straightforward. Currently we output ruby Qfalse

  def process_false(exp)
         return "Qfalse"
  end

  ##
  # Global variables, evil but necessary.
  #
  # TODO: get the case statement out by using proper bootstrap in genv.

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

  ##
  # Hash values, currently unsupported, but plans are in the works.

  def process_hash(exp)
    no(exp)
  end

  ##
  # Instance Variable Assignment

  def process_iasgn(exp)
    name = exp.shift
    val = process exp.shift
    "self->#{name.to_s.sub(/^@/, '')} = #{val}"
  end

  ##
  # Conditional statements
  #
  # TODO: implementation is ugly as hell... PLEASE try to clean

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
      out << "for (#{index} = 0; #{index} < #{enum}.length; ++#{index}) {"
      out << "#{c_type @env.lookup(var)} #{var} = #{enum}.contents[#{index}];"
      out << body
      out << "}"
    end

    return out.join("\n")
  end

  ##
  # Instance Variable Access

  def process_ivar(exp)
    name = exp.shift
    "self->#{name.to_s.sub(/^@/, '')}"
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
    var_type = c_type exp_type

    if exp_type.list? then
      assert_type args, :array

      raise "array must be of one type" unless args.sexp_type == Type.homo

      # HACK: until we figure out properly what to do w/ zarray
      # before we know what its type is, we will default to long.
      array_type = args.sexp_types.empty? ? 'long' : c_type(args.sexp_types.first)

      args.shift
      out << "#{var}.length = #{arg_count};\n"
      out << "#{var}.contents = (#{array_type}*) malloc(sizeof(#{array_type}) * #{var}.length);\n"
      args.each_with_index do |o,i|
        out << "#{var}.contents[#{i}] = #{process o};\n"
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
    # TODO what about floats and big numbers?

    value = exp.shift
    sexp_type = exp.sexp_type
    case sexp_type
    when Type.long, Type.float then
      return value.to_s
    when Type.symbol then
      return ":" + value.to_s
    else
      raise "Bug! no: Unknown literal #{value}:#{value.class}"
    end
  end

  ##
  # Local variable

  def process_lvar(exp)
    name = exp.shift
    # do nothing at this stage, var should have been checked for
    # existance already.
    return name.to_s
  end

  ##
  # Nil, currently ruby nil, not C NULL (0).

  def process_nil(exp)
    return "Qnil"
  end

  ##
  # Nil, currently ruby nil, not C NULL (0).

  def process_not(exp)
    term = process exp.shift
    return "!(#{term})"
  end

  ##
  # Or assignment (||=), currently unsupported, but only because of
  # laziness.

  def process_op_asgn_or(exp)
    no(exp)
  end

  ##
  # Logical or. Nothing exciting here

  def process_or(exp)
    lhs = process exp.shift
    rhs = process exp.shift

    return "#{lhs} || #{rhs}"
  end

  ##
  # Return statement. Nothing exciting here

  def process_return(exp)
    return "return #{process exp.shift}"
  end

  ##
  # Scope has no real equivalent in C-land, except that like
  # process_block above. We put variable declarations here before the
  # body and use this as our opportunity to open a variable
  # scope. Crafty, no?

  def process_scope(exp)
    declarations = []
    body = nil
    @env.scope do
      body = process exp.shift unless exp.empty?
      @env.current.sort_by { |v,t| v.to_s }.each do |var, var_type|
        var_type = c_type var_type
        declarations << "#{var_type} #{var};\n"
      end
    end
    return "{\n#{declarations}#{body}}"
  end

  ##
  # Strings. woot.

  def process_str(exp)
    s = exp.shift.gsub(/\n/, '\\n')
    return "\"#{s}\""
  end

  ##
  # Truth... what is truth? In this case, Qtrue.

  def process_true(exp)
    return "Qtrue"
  end

  ##
  # While block. Nothing exciting here.

  def process_while(exp)
    cond = process exp.shift
    body = process exp.shift
    body += ";" unless body =~ /;/
    is_precondition = exp.shift
    code = "while (#{cond}) {\n#{body.strip}\n}"
    code = "{\n#{body.strip}\n} while (#{cond})" unless is_precondition
    return code
  end

end
