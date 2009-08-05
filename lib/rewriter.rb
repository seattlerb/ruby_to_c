
begin require 'rubygems'; rescue LoadError; end
require 'sexp'
require 'sexp_processor'
require 'unique'

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
  def rewrite_defn(exp)
    case exp.last[0]
    when :ivar then
      ivar = exp.pop
      exp.push s(:scope, s(:block, s(:return, ivar)))
    when :attrset then
      var = exp.pop
      exp.push s(:scope,
                 s(:block,
                   s(:return, s(:iasgn, var.last, s(:lvar, :arg)))))
    end
    exp
  end
end

