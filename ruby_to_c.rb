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
    self.default_method = :translate
  end

  def translate(exp)
    return nil if exp.nil?

    @original = exp.deep_clone if exp.first == :defn

    node_type = exp.shift

    c_code = 
      case node_type
      when :args then
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
      when :array then
        code = []
        until exp.empty? do
          code << translate(exp.shift)
        end
        code
      when :block then
        code = []
        until exp.empty? do
          thingy = exp.shift
          result = translate(thingy)
          code << result
        end
        args = code.shift
        body = code.join(";\n")
        body += ";" unless body =~ /[;}]\Z/
        body += "\n"
        [args, body]
      when :call then
        lvar = translate exp.shift
        method = exp.shift
        unless exp.empty? then
          rvar = translate exp.shift
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
      when :dasgn_curr then
        var = exp.shift
        arg = var.shift
        typ = c_type var.shift
        [typ, arg]
      when :defn then
        name = exp.shift
        args, body = translate exp.shift
        ret_type = c_type exp.shift
        "#{ret_type}\n#{name}(#{args}) {#{body}}"
      when :dvar then
        exp.shift
      when :false then
        "0"
      when :fcall then
        name = exp.shift
        args = translate exp.shift
        args = args.join ', '
        "#{name}(#{args})"
      when :gvar then
        name = exp.shift
        type = exp.shift
        case name
        when "$stderr" then
          "stderr"
        else
          raise "Bug! Unhandled gvar #{name} (type = #{type})"
        end
      when :if then
        cond_part = translate exp.shift

        result = "if (#{cond_part})"

        then_block = ! exp.first.nil? && exp.first.first == :block
        then_part  = translate exp.shift
        else_block = ! exp.first.nil? && exp.first.first == :block
        else_part  = translate exp.shift

        then_part = "" if then_part.nil?
        else_part = "" if else_part.nil?

        # TODO: I want braces all the time
#        result += " {" if then_block
        result += " {\n"
        
        # HACK: rewrite blocks you stupid fucker
        then_part = then_part.join(";\n") if Array === then_part
        then_part += ";" unless then_part =~ /[;}]\Z/
        # HACK: um... deal with nil correctly (see unless support)
        result += then_part.to_s # + ";"
        result += ";" if then_part.nil?
        #result += "\n" if then_block or not else_block
#        result += "}" if then_block
        result += "\n" unless result =~ /\n\Z/
        result += "}"

        if else_part != "" then
#          result += "\n" if not then_block
#          result += " " if then_block
          result += " else {\n"
#          result += " {" if else_block
#          result += " {"
#          result += "\n"
          else_part = else_part.join(";\n") if Array === else_part
          else_part += ";" unless else_part =~ /[;}]\Z/
          result += else_part
#          result += ";" if else_part.nil?
#          result += "\n}" if else_block
          result += "\n}"
        end

#         if else_part then
#           "if (#{cond_part}) {\n#{then_part};\n} else {\n#{else_part};\n}"
#         else
#           "if (#{cond_part}) {\n#{then_part};\n}"
#         end
        result
      when :iter then
        iter, method = translate exp.shift
        arg_type, arg_name = translate exp.shift
        body_part = translate exp.shift
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
      when :lasgn then
        typ = exp.pop
        unless typ.nil? then
          typ = c_type typ
        end
        name = exp.shift
        args = []
        until exp.empty? do
          sub_exp = exp.shift
          args << translate(sub_exp)
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
      when :lit then
        exp.shift.to_s
      when :lvar then
        exp.shift
      when :nil then
        "Qnil"
      when :or then
        exps = []
        until exp.empty? do
          exps << translate(exp.shift)
        end
        exps.join(" || ")
      when :return then
        "return #{translate exp.shift}"
      when :scope then
        args, body = translate exp.shift
        if body.nil? or body.empty? then
          body = "\n"
        else
          body = "\n#{body}"
        end
        [args, body]
      when :str then
        "\"#{exp.shift}\""
      when :true then # FIX: this should be not zero
        "1"
        # We purposefully do not support these node types
#       when :case then
#         var = translate(exp.shift)
#         bod = []
#         els = translate(exp.pop)
#         until exp.empty? do
#           thingy = exp.shift
#           result = translate(thingy)
#           bod << result
#         end
#         "switch (#{var}) {\n#{bod.join('')}" + (els.nil? ? '' : "default:\n#{els};\nbreak;\n") + "}"
#       when :when then
#         code = []
#         ary = exp.shift
#         ary.shift # nuke :array
#         code << ary.map do |thingy|
#           "case " + translate(thingy) + ":\n"
#         end
#         body = translate(exp.shift).to_a
#         unless body.empty? then
#           code << "#{body.join(";\n")};\nbreak;\n"
#         else
#           code << "break;\n"
#         end
      when :case, :when, :rescue, :const, :dstr then
        raise SyntaxError, "'#{node_type}' is not a supported node type for translation (yet?)."
      else
        raise "Bug! Unknown node type #{node_type.inspect} in #{([node_type] + exp).inspect}"
      end

    raise "exp is not empty!!! #{exp.inspect} from #{@original.inspect}" unless exp.empty?
    c_code

  end

end

