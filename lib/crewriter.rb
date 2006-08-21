# -*- ruby -*-

begin require 'rubygems'; rescue LoadError; end
require 'type'
require 'sexp_processor'
require 'environment'

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

  attr_reader :env
  attr_reader :extra_methods

  def initialize # :nodoc:
    super
    self.auto_shift_type = true
    self.expected = TypedSexp
    @env = Environment.new
    @extra_methods = []
  end

  def free # REFACTOR: this is a violation of responsibility, should be in Env
    parent = @env.env[0..-2]
    bound_in_parent = parent.map { |h| h.keys }.flatten

    env = @env.all

    free = env.select { |k, (t, v)| bound_in_parent.include? k or not v }
    vars = free.map { |k, (t, v)| [k, t] }
    return vars
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

  def process_class(exp)
    klassname = exp.shift
    superklassname = exp.shift

    methods = []

    until exp.empty? do
      methods << process(exp.shift)
    end

    @extra_methods.reverse_each do |defx| methods.unshift defx end
    @extra_methods.clear

    return t(:class, klassname, superklassname, *methods)
  end

  def process_iter(exp)
    iter_method_name = Unique.next

    call = process exp.shift
    vars = process exp.shift
    body = nil

    free_vars = @env.scope do
      body = process exp.shift
      self.free
    end

    var_names = var_names_in vars
    dasgns = t(:array, *var_names.map { |name, type| t(:dasgn_curr, name, type)})
    frees  = t(:array, *free_vars.map { |name, type| t(:lvar, name, type) })
    args   = t(:args, dasgns, frees)

    defx = t(:defx,
             iter_method_name,
             t(:args, Unique.next, Unique.next),
             t(:scope,
               t(:block,
                 body)), Type.void)

    @extra_methods << defx

    return t(:iter, call, args, iter_method_name)
  end

  def process_lasgn(exp)
    name = exp.shift
    value = process(exp.shift)

    @env.add name, exp.sexp_type
    @env.set_val name, true

    return t(:lasgn, name, value, exp.sexp_type)
  end

  def process_lvar(exp)
    name = exp.shift

    @env.add name, Type.value
    @env.lookup name rescue @env.set_val name, false

    return t(:lvar, name, exp.sexp_type)
  end

  def var_names_in(exp)
    return [[exp.last, exp.sexp_type]] if exp.length == 2 and not Sexp === exp.last

    var_names = []
    exp.each_of_type :dasgn_curr do |sexp|
      var_names << [sexp.sexp_body.first, sexp.sexp_type]
    end
    return var_names
  end
end
