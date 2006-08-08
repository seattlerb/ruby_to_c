begin require 'rubygems'; rescue LoadError; end
require 'parse_tree'
require 'environment'
require 'type'
require 'sexp'
require 'sexp_processor'
require 'unique'

class IterRewriter < SexpProcessor

  attr_reader :env

  attr_reader :iter_functions

  def initialize
    super
    self.auto_shift_type = true
    @env = Environment.new
    @iter_functions = []
  end

  def free
    parent = @env.env[0..-2]
    bound_in_parent = parent.map { |h| h.keys }.flatten

    env = @env.all

    free = env.select { |k, (_, v)| bound_in_parent.include? k or not v }
    vars = free.map { |k,| k }
    return vars
  end

  def process_class(exp)
    klassname = exp.shift
    superklassname = exp.shift

    methods = []

    until exp.empty? do
      methods << process(exp.shift)
    end

    @iter_functions.reverse_each do |defx| methods.unshift defx end
    @iter_functions.clear

    return s(:class, klassname, superklassname, *methods)
  end

  def process_iter(exp)
    iter_method_name = Unique.next

    call = process exp.shift
    vars = process exp.shift
    body = nil

    free = @env.scope do
      body = process exp.shift
      self.free
    end

    var_names = var_names_in vars

    dasgns = s(:array)
    var_names.each do |name| dasgns << s(:dasgn_curr, name) end

    frees = s(:array)
    free.each do |name| frees << s(:lvar, name) end

    args = s(:args, dasgns, frees)

    defx = s(:defx,
             iter_method_name,
             s(:args, Unique.next, Unique.next),
             s(:scope,
               s(:block,
                 body)))

    @iter_functions << defx

    return s(:iter, call, args, iter_method_name)
  end

  def process_lasgn(exp)
    name = exp.shift
    value = process(exp.shift)

    @env.add name, Type.value
    @env.set_val name, true

    return s(:lasgn, name, value)
  end

  def process_lvar(exp)
    name = exp.shift

    @env.add name, Type.value
    @env.lookup name rescue @env.set_val name, false

    return s(:lvar, name)
  end

  def var_names_in(exp)
    return [exp.last] if exp.length == 2 and not Sexp === exp.last

    var_names = []
    exp.each_of_type :dasgn_curr do |sexp|
      var_names << sexp.sexp_body.first
    end
    return var_names
  end

end

