begin require 'rubygems'; rescue LoadError; end
require 'type'
require 'sexp_processor'

##
# CRewriter (should probably move this out to its own file) does
# rewritings that are language specific to C.

class CRewriter < SexpProcessor

  ##
  # REWRITES maps a function signature to a proc responsible for
  # generating the appropriate sexp for that rewriting.

  REWRITES = {
    [Type.str, :+, Type.str] => proc { |l,n,r|
      t(:call, nil, :strcat, r.unshift(r.shift, l), Type.str)
    },
    [Type.file, :puts, Type.str] => proc { |l,n,r|
      t(:call, nil, :fputs, r.push(l))
    },
  }

  def initialize # :nodoc:
    super
    self.auto_shift_type = true
    self.expected = TypedSexp
  end

  ##
  # Rewrites function calls by looking them up in the REWRITES map. If
  # a match exists, it invokes the block passing in the lhs, rhs, and
  # function name. If one does not exist, it simply repacks the sexp
  # and sends it along.

  def process_call(exp)
    lhs = process exp.shift
    name = exp.shift
    rhs = process exp.shift

    lhs_type = lhs.sexp_type rescue nil
    type_signature = [lhs_type, name]
    type_signature += rhs[1..-1].map { |sexp| sexp.sexp_type } unless rhs.nil?

    result = if REWRITES.has_key? type_signature then
               REWRITES[type_signature].call(lhs, name, rhs)
             else
               t(:call, lhs, name, rhs, exp.sexp_type)
             end

    return result
  end
end


