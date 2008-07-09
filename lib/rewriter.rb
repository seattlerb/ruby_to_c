
begin require 'rubygems'; rescue LoadError; end
require 'sexp'
require 'sexp_processor'
require 'unique'
require 'unified_ruby'

class Sexp
  # add arglist because we introduce the new array type in this file
  @@array_types << :arglist
end

##
# Rewriter (probably should be renamed) is a first-pass filter that
# normalizes some of ruby's ASTs to make them more processable later
# in the pipeline. It only has processors for what it is interested
# in, so real the individual methods for a better understanding of
# what it does.

class Rewriter < SexpProcessor
  include UnifiedRuby

#   def initialize # :nodoc:
#     super
#     self.auto_shift_type = true
#     self.unsupported = [ :cfunc, ]
#     # self.debug[:defn] = /method/ # coolest debugging feature ever
#   end

#   def process(sexp)
#     sexp = Sexp.from_array(sexp) if sexp and sexp.class == Array
#     super
#   end

#   ##
#   # Rewrites :attrasgn nodes to the unified :call format:
#   #
#   # [:attrasgn, lhs, :name=, args],
#   #
#   # becomes:
#   #
#   # [:call, lhs, :name=, args]

#   def process_attrasgn(exp)
#     lhs = process exp.shift
#     name = exp.shift
#     args = (exp.empty? ? nil : process(exp.shift))
#     args[0] = :arglist unless args.nil?

#     s(:call, lhs, name, args)
#   end

#   ##
#   # Rewrites :case/:when nodes as nested :if nodes.

#   def process_case(exp)
#     result = s()
#     var = process exp.shift
#     else_stmt = process exp.pop

#     new_exp = result
    
#     until exp.empty? do
#       c = exp.shift
#       # start a new scope and move to it
#       new_exp << s(:if)
#       new_exp = new_exp.last

#       assert_type c, :when
#       ignored_type, vars, stmts = process(c)

#       vars = vars.map { |v| s(:call,
#                               var.deep_clone,
#                               :===,
#                               s(:arglist, process(v)))}
#       if vars.size > 1 then

#         # building from the bottom up, so everything is bizarro-sexp
#         # BIZARRO-SEXP NO LIKE OR!
#         or_sexp = vars.inject(s(:or, *vars.slice!(-2,2))) do |lhs, rhs|
#           s(:or, rhs, lhs)
#         end

#         new_exp << or_sexp
#       else
#         new_exp << vars.first
#       end
#       new_exp << stmts
#     end
#     new_exp << else_stmt

#     result.first
#   end

#   ##
#   # I'm not really sure what this is for, other than to guarantee that
#   # there are 4 elements in the sexp.

#   def process_if(exp)
#     cond = process exp.shift
#     t = process(exp.shift) || nil # FIX: nil is bad, we need to switch to dummy
#     f = process(exp.shift) || nil
#     return s(:if, cond, t, f)
#   end

#   ##
#   # Rewrites specific :iter nodes into while loops:
#   # [DOC]

#   def process_iter(exp)
#     call = process exp.shift
#     var  = exp.shift
#     body = exp.empty? ? s(:scope, s(:block)) : process(exp.shift)

#     var = case var
#           when 0 then
#             var # leave 0
#           when nil then
#             s(:dasgn_curr, Unique.next)
#           else
#             process var
#           end

#     return s(:iter, call, var, body) # if call.first == :postexe
#   end

#   ##
#   # Rewrites self into lvars

#   def process_self(exp)
#     s(:lvar, :self)
#   end

#   ##
#   # Rewrites until nodes into while nodes.

#   def process_until(exp)
#     cond = process s(:not, exp.shift)
#     body = process exp.shift
#     raise "boo" if exp.empty?
#     is_precondition = exp.shift
#     s(:while, cond, body, is_precondition)
#   end

#   ##
#   # Rewrites :when nodes so :case can digest it into if/else structure
#   # [:when, [args], body]

#   def process_when(exp)
#     vars = exp.shift
#     assert_type vars, :array
#     vars.shift # nuke vars type
#     stmts = process(exp)
#     return s(:when, vars, stmts.first)
#   end

#   ##
#   # Rewrites :zarray nodes to :array with no args.

#   def process_zarray(exp)
#     return s(:array)
#   end

  def rewrite_defn(exp) # extends UnifiedRuby's rewriter
    exp = super

    case exp.last[0]
    when :ivar then
      ivar = exp.pop
      exp.pop # FIX: huh? extra args?
      exp.push s(:scope, s(:block, s(:return, ivar)))
    when :attrset then
      var = exp.pop
      exp.pop # FIX: huh? extra args?
      exp.pop # FIX: huh? extra args?
      exp.push s(:args, :arg)
      exp.push s(:scope,
                 s(:block,
                   s(:return, s(:iasgn, var.last, s(:lvar, :arg)))))
    end
    exp
  end


#   def rewrite_call(exp) # extends UnifiedRuby's rewriter
#     exp = super
#     exp[-1] = s(:arglist, exp[-1]) if exp[-1][0] == :splat
#     exp[-1] = nil if exp[-1] == s(:arglist)
#     exp
#   end

#   def rewrite_resbody(exp)
#     exp[1] = nil if exp[1] == s(:array)
#     exp
#   end
end

