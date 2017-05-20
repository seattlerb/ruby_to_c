$TESTING = false unless defined? $TESTING

require 'pp'
begin require 'rubygems'; rescue LoadError; end
require 'ruby_parser'
require 'sexp_processor'
require 'composite_sexp_processor'

require 'type_checker'
require 'rewriter'
require 'crewriter'
require 'r2cenvironment'

##
# The whole point of this project! RubyToC is an actually very simple
# SexpProcessor that does the final conversion from Sexp to C code.
# This class has more unsupported nodes than any other (on
# purpose--we'd like TypeChecker and friends to be as generally useful
# as possible), and as a result, supports a very small subset of ruby.

class RubyToAnsiC < SexpProcessor

  VERSION = '1.0.0.9'

  # TODO: remove me
  def no(exp) # :nodoc:
    raise "no: #{caller[0].split[1]} #{exp.inspect}"
  end

  ##
  # Returns a textual version of a C type that corresponds to a sexp
  # type.

  def self.c_type(typ)
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
        "bool"
      when :void then
        "void"
      when :homo then
        "void *" # HACK
      when :value, :unknown then
        "void *" # HACK
# HACK: uncomment this and fix the above when you want to have good tests
#      when :unknown then
#        raise "You should not have unknown types by now!"
      else
        raise "Bug! Unknown type #{typ.inspect} in c_type"
      end

    base_type += " *" if typ.list? unless typ.unknown?

    base_type
  end

  ##
  # Provides a place to put things at the file scope.
  # Be smart, make them static (hence the name).

  attr_reader :statics

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
#define case_equal_long(x, y) ((x) == (y))
// END METARUBY PREAMBLE
" + self.prototypes.join('')
  end

  ##
  # Lazy initializer for the composite RubytoC translator chain.

  def self.translator
    unless defined? @translator then
      @translator = CompositeSexpProcessor.new
      @translator << Rewriter.new
      @translator << TypeChecker.new
#      @translator << CRewriter.new
      @translator << RubyToAnsiC.new
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

  def initialize # :nodoc:
    super
    @env = ::R2CEnvironment.new
    self.auto_shift_type = true
    self.unsupported = [:alias, :alloca, :argscat, :argspush, :attrasgn, :attrset, :back_ref, :begin, :block_arg, :block_pass, :bmethod, :break, :case, :cdecl, :cfunc, :colon2, :colon3, :cref, :cvasgn, :cvdecl, :dasgn, :defined, :defs, :dmethod, :dot2, :dot3, :dregx, :dregx_once, :dstr, :dsym, :dxstr, :ensure, :evstr, :fbody, :fcall, :flip2, :flip3, :for, :gasgn, :hash, :ifunc, :last, :masgn, :match, :match2, :match3, :memo, :method, :module, :newline, :next, :nth_ref, :op_asgn_or, :op_asgn1, :op_asgn2, :op_asgn_and, :opt_n, :postexe, :redo, :resbody, :rescue, :retry, :sclass, :self, :splat, :super, :svalue, :to_ary, :undef, :until, :valias, :vcall, :when, :xstr, :yield, :zarray, :zsuper]

    self.strict = true
    self.expected = String

    @statics = []
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
  # Arglist is used by call arg lists.

  def process_arglist(exp)
    return '' if exp.empty?
    return process_array(exp)
  end

  ##
  # Argument List including variable types.

  def process_args(exp)
    args = []

    until exp.empty? do
      arg = exp.shift
      name = arg.first.to_s.sub(/^\*/, '').intern
      type = arg.c_type
      @env.add name, type
      args << "#{self.class.c_type(type)} #{name}"
    end

    return "(#{args.join ', '})"
  end

  ##
  # Array is used as call arg lists and as initializers for variables.

  def process_array(exp)
    return "rb_ary_new()" if exp.empty? # HACK FIX! not ansi c!

    code = []
    until exp.empty? do
      code << process(exp.shift) 
    end

    s = code.join ', '

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

    receiver_type = CType.unknown
    unless receiver.nil? then
      receiver_type = receiver.c_type
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
      args = process exp.shift
      return "#{receiver}[#{args}]"
    when :nil?
      exp.clear
      return receiver.to_s
    else
      args = process exp.shift

      if receiver.nil? and args.nil? then
        args = ""
      elsif receiver.nil? then
        # nothing to do 
      elsif args.nil? or args.empty? then
        args = receiver
      else
        args = "#{receiver}, #{args}"
      end

      args = '' if args == 'rb_ary_new()' # HACK

      return "#{name}(#{args})"
    end
  end

  ##
  # DOC

  def process_class(exp)
    name = exp.shift
    superklass = exp.shift

    result = []

    until exp.empty? do
      # HACK: cheating!
      result << process(exp.shift)
    end

    result.unshift(*statics)
    result.unshift "// class #{name} < #{superklass}"

    return result.join("\n\n")
  end

  ##
  # Constants, must be pre-defined in the global env for ansi c.

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

  def process_dasgn_curr(exp) # TODO: audit against obfuscator
    var = exp.shift
    @env.add var.to_sym, exp.c_type
    return var.to_s
  end

  ##
  # Function definition

  METHOD_MAP = { # TODO: steal map from ZenTest
    :| => "or",
    :& => "and",
    :^ => "xor",
  }

  def process_defn(exp) # TODO: audit against obfuscator
    name = exp.shift
    name = METHOD_MAP[name] if METHOD_MAP.has_key? name
    name = name.to_s.sub(/(.*)\?$/, 'is_\1').intern
    args = process exp.shift
    body = process exp.shift
    function_type = exp.c_type

    ret_type = self.class.c_type function_type.list_type.return_type

    @prototypes << "#{ret_type} #{name}#{args};\n"
    "#{ret_type}\n#{name}#{args} #{body}"
  end

  def process_defx(exp) # TODO: audit against obfuscator
    return process_defn(exp)
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
    @env.add var.to_sym, exp.c_type
    return var.to_s
  end

  ##
  # DOC - TODO: what is this?!?

  def process_error(exp)
    return exp.shift
  end

  ##
  # False. Pretty straightforward.

  def process_false(exp)
    return "0"
  end

  # TODO: process_gasgn

  ##
  # Global variables, evil but necessary.
  #
  # TODO: get the case statement out by using proper bootstrap in genv.

  def process_gvar(exp)
    name = exp.shift
    type = exp.c_type
    case name
    when :$stderr then
      "stderr"
    else
      raise "Bug! Unhandled gvar #{name.inspect} (type = #{type})"
    end
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

    then_part  = process exp.shift
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

  def process_iter(exp) # TODO: audit against obfuscator
    out = []
    # Only support enums in C-land
    raise UnsupportedNodeError if exp[0][1].nil? # HACK ugly
    @env.scope do
      enum = exp[0][1][1] # HACK ugly t(:iter, t(:call, lhs <-- get lhs

      _ = process exp.shift
      var  = process(exp.shift).intern # semi-HACK-y
      body = process exp.shift
      index = "index_#{var}"

      body += ";" unless body =~ /[;}]\Z/
      body.gsub!(/\n\n+/, "\n")

      out << "unsigned long #{index};"
      out << "for (#{index} = 0; #{enum}[#{index}] != NULL; ++#{index}) {"
      out << "#{self.class.c_type @env.lookup(var)} #{var} = #{enum}[#{index}];"
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

      # HACK: until we figure out properly what to do w/ zarray
      # before we know what its type is, we will default to long.
      array_type = args.c_types.empty? ? 'void *' : self.class.c_type(args.c_types.first)

      args.shift # :arglist
# TODO: look into alloca
      out << "#{var} = (#{array_type}) malloc(sizeof(#{array_type}) * #{args.length});\n"
      args.each_with_index do |o,i|
        out << "#{var}[#{i}] = #{process o};\n"
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
    c_type = exp.c_type
    case c_type
    when CType.long, CType.float then
      return value.to_s
    when CType.symbol then
      return value.to_s.inspect # HACK wrong! write test!
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

  # TODO: pull masgn from obfuscator
  # TODO: pull module from obfuscator
  # TODO: pull next from obfuscator

  ##
  # Nil, currently ruby nil, not C NULL (0).

  def process_nil(exp)
    return "NULL"
  end

  ##
  # Nil, currently ruby nil, not C NULL (0).

  def process_not(exp)
    term = process exp.shift
    return "!(#{term})"
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
    declarations, body = with_scope do
      process exp.shift unless exp.empty?
    end

    declarations = declarations.reject { |d| d =~ / static_/ }

    result = []
    result << "{"
    result << declarations.join("\n") unless declarations.empty?
    result << body.chomp if body
    result << "}"
    
    return result.join("\n")
  end

  ##
  # A bogus ruby sexp type for generating static variable declarations

  def process_static(exp)
    return exp.shift
  end

  ##
  # Strings. woot.

  def process_str(exp)
    return exp.shift.inspect
  end

  # TODO: pull scope from obfuscator

  ##
  # Truth... what is truth?

  def process_true(exp)
    return "1"
  end

  ##
  # While block. Nothing exciting here.

  def process_while(exp)
    cond = process exp.shift
    body = process exp.shift
    body += ";" unless body =~ /;/
    is_precondition = exp.shift
    if is_precondition then
      return "while (#{cond}) {\n#{body.strip}\n}"
    else
      return "{\n#{body.strip}\n} while (#{cond})"
    end
  end

  def with_scope
    declarations = []
    result = nil
    outer_scope = @env.all.keys

    @env.scope do
      result = yield
      @env.current.sort_by { |v,_| v.to_s }.each do |var, (type,val)|
        next if outer_scope.include? var
        decl = "#{self.class.c_type type} #{var}"
        case val
        when nil then
          # do nothing
        when /^\[/ then
          decl << "#{val}"
        else
          decl << " = #{val}"
        end
        decl << ';'
        declarations << decl
      end
    end

    return declarations, result
  end
end
