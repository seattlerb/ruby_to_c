require 'sexp_processor'
require 'parse_tree'
require 'rewriter'
require 'support'

# TODO: calls to sexp_type should probably be replaced w/ better Sexp API

class TypeChecker < SexpProcessor

  require 'bootstrap'

  attr_reader :tree
  attr_reader :env
  attr_reader :genv
  attr_reader :functions

  @@parser = ParseTree.new
  @@rewriter = Rewriter.new

  def translate(klass, method = nil)
    # HACK FIX this is horrid, and entirely eric's fault, and requires a real pipeline
    sexp = @@parser.parse_tree klass, method
    sexp = @@rewriter.process sexp
    self.process sexp
  end

  def self.translate(klass, method = nil)
    self.new.translate(klass, method)
  end

  def self.process(klass, method=nil)
    processor = self.new
    rewriter = Rewriter.new
    sexp = ParseTree.new.parse_tree(klass, method)
    sexp = [sexp] unless Array === sexp.first

    result = []
    sexp.each do |exp|
      # TODO: we need a composite processor to chain these cleanly
      sexp = rewriter.process(exp)
      result << processor.process(sexp)
    end

    result
  end

  def initialize
    super
    @current_function_name = nil
    @env = Environment.new
    @genv = Environment.new
    @functions = {}
    self.auto_shift_type = true
    self.strict = true

    @env.extend

    bootstrap
  end

  def bootstrap
    @genv.extend
    @genv.add "$stderr", Type.file

    parser = ParseTree.new
    rewriter = Rewriter.new
    # TODO use the chain
    TypeChecker::Bootstrap.instance_methods(false).each do |meth|
      parsed = parser.parse_tree TypeChecker::Bootstrap, meth
      rewritten = rewriter.process parsed
      process rewritten
    end
  end

  ##
  # Expects a list of variable names and returns a arg list of
  # name, type pairs.

  def process_args(exp)
    formals = Sexp.new :args
    types = []

    until exp.empty? do
      arg = exp.shift
      type = Type.unknown
      @env.add arg, type
      formals << Sexp.new(arg, type)
      types << type
    end

    return formals
  end

  ##
  # Expects list of expressions.  Returns a corresponding list of
  # expressions and types.

  def process_array(exp)
    types = []
    vars = Sexp.new :array
    until exp.empty? do
      var = process exp.shift
      vars << var
      types << var.sexp_type
    end
    # HACK!!! omg types cannot be an array, but we don't ... yeah. brokey.
    # vars.sexp_type = types
    vars
  end

  ##
  # Expects a list of expressions.  Processes each expression and
  # returns the unknown type.

  def process_block(exp)
    nodes = Sexp.new :block, Type.unknown
    until exp.empty? do
      nodes << process(exp.shift)
    end
    nodes
  end

  ##
  # Expects a function name, an optional lhs, and an optional
  # list of arguments.
  #
  # Unifies the arguments according to the method name.

  def process_call(exp)
    name = exp.shift
    lhs = process exp.shift     # can be nil
    args = process exp.shift

    arg_types = if args.nil? then
                  []
                else
                  if args.first == :array then
                    args.sexp_types
                  else
                    [args.sexp_type]
                  end
                end

    if name == "===" then
      rhs = args[1]
      raise "lhs of === may not be nil" if lhs.nil?
      raise "rhs of === may not be nil" if rhs.nil?
      raise "Help! I can't figure out what kind of #=== comparison to use" if
        lhs.sexp_type.unknown? and rhs.sexp_type.unknown?
      equal_type = lhs.sexp_type.unknown? ? rhs.sexp_type : lhs.sexp_type
      name = "case_equal_#{equal_type.list_type}"
    end

    function_type = @functions[name]
    return_type = Type.unknown

    unless lhs.nil? or lhs.sexp_type.nil? then
      arg_types.unshift lhs.sexp_type
    end

    if function_type.nil?  then
      @functions[name] = Type.function arg_types, return_type
    else
      function_type.unify Type.function(arg_types, return_type)
      return_type = function_type.list_type.return_type
    end

    return Sexp.new(:call, name, lhs, args, return_type)
  end

  ##
  # Expects a single variable.  Returns the expression and the unknown type.

  def process_dasgn_curr(exp)
    name = exp.shift
    type = Type.unknown
    @env.add name, type

    return Sexp.new(:dasgn_curr, name, type)
  end

  ##
  # Expects a function name and an expression.  Returns an augmented
  # expression and the function type.

  def process_defn(exp)
    return_type = Type.unknown
    function_type = nil
    name = exp.shift

    @current_function_name = name
    @env.extend

    args = process exp.shift

    unless @functions.has_key? name then
      @functions[name] = Type.function args.sexp_types, return_type
    end
    body = process exp.shift
    body_type = body.sexp_type

    @env.unextend
    @current_function_name = nil

    function_type = @functions[name]

    return_type.unify Type.void if return_type == Type.unknown

    args.sexp_types.each_with_index do |type, i|
      type.unify function_type.list_type.formal_types[i]
    end

    return Sexp.new(:defn, name, args, body, function_type)
  end

  ##
  # Expects a variable name.  Returns the expression and variable type.

  def process_dvar(exp)
    name = exp.shift
    type = @env.lookup name
    return Sexp.new(:dvar, name, type)
  end

  ##
  # :if expects a conditional, if branch and else branch expressions.
  # Unifies and returns the type of the three expressions.

  def process_if(exp)
    cond_exp  = process exp.shift
    then_exp  = process exp.shift
    else_exp  = process exp.shift rescue nil # might be empty

    cond_exp.sexp_type.unify Type.bool
    then_exp.sexp_type.unify else_exp.sexp_type unless then_exp.nil? or else_exp.nil?

    # FIX: at least document this
    type = then_exp.sexp_type unless then_exp.nil?
    type = else_exp.sexp_type unless else_exp.nil?

    return Sexp.new(:if, cond_exp, then_exp, else_exp, type)
  end

  ##
  # Extracts the type of the rhs from the call expression and
  # unifies it with a list type.  Then unifies the type of the
  # rhs with the dynamic arg and then processes the body.
  # 
  # Returns the expression and the void type.

  def process_iter(exp)
    call_exp = process exp.shift
    dargs_exp = process exp.shift
    body_exp = process exp.shift

    lhs = call_exp[2]
    Type.unknown_list.unify lhs.sexp_type
    Type.new(lhs.sexp_type.list_type).unify dargs_exp.sexp_type

    return Sexp.new(:iter, call_exp, dargs_exp, body_exp, Type.void)
  end

  ##
  # Expects a variable name and an expression.  Returns an augmented
  # expression and the type of the variable.

  def process_lasgn(exp)
    name = exp.shift
    arg_exp = nil
    arg_type = nil
    var_type = @env.lookup name rescue nil

    sub_exp = exp.shift
    sub_exp_type = sub_exp.first
    arg_exp = process sub_exp

    if sub_exp_type == :array then
      arg_type = arg_exp.sexp_types
      arg_type = arg_type.inject(Type.unknown) do |t1, t2|
        t1.unify t2
      end
      arg_type = arg_type.dup # singleton type
      arg_type.list = true
    else
      arg_type = arg_exp.sexp_type
    end

    if var_type.nil? then
      @env.add name, arg_type
      var_type = arg_type
    else
      var_type.unify arg_type
    end

    return Sexp.new(:lasgn, name, arg_exp, var_type)
  end

  ##
  # A literal value.  Returns the expression and the type of the literal.

  def process_lit(exp)
    value = exp.shift
    type = nil

    case value
    when Fixnum then
      type = Type.long
    else
      raise "Bug! Unknown literal #{value}"
    end

    return Sexp.new(:lit, value, type)
  end

  ##
  # Expects a variable name.  Returns the expression and variable type.

  def process_lvar(exp)
    name = exp.shift
    type = @env.lookup name
    
    return Sexp.new(:lvar, name, type)
  end

  ##
  # Expects a global variable name.  Returns an augmented expression and the
  # variable type

  def process_gvar(exp)
    name = exp.shift
    type = @genv.lookup name rescue nil
    if type.nil? then
      type = Type.unknown
      @genv.add name, type
    end
    return Sexp.new(:gvar, name, type)
  end

  ##
  # Empty expression. Returns the expression and the value type.

  def process_nil(exp)
    # don't do a fucking thing until... we have something to do
    # HACK: wtf to do here? (what type is nil?!?!)
    return Sexp.new(:nil, Type.value)
  end

  def process_or(exp)
    rhs = process exp.shift
    lhs = process exp.shift

    rhs_type = rhs.sexp_type
    lhs_type = lhs.sexp_type

    rhs_type.unify lhs_type
    rhs_type.unify Type.bool

    return Sexp.new(:or, rhs, lhs, Type.bool)
  end

  ##
  # :rescue expects a try and rescue block.  Unifies and returns their
  # type.

  def process_rescue(exp)
    # TODO: I think there is also an else stmt. Should make it
    # mandatory, not optional.
    # TODO: test me
    try_block = check(exp.shift, tree)
    rescue_block = check(exp.shift, tree)
    try_block.unify rescue_block
    raise "not done yet"
    return try_block
  end

  ##
  # Expects a list of expressions.  Returns the processed expression and the
  # void type.

  ##
  # Expects an expression.  Unifies the return type with the current method's
  # return type and returns the expression and the void type.

  def process_return(exp)
    body = process exp.shift
    fun_type = @functions[@current_function_name]
    raise "Definition of #{@current_function_name.inspect} not found in function list" if fun_type.nil?
    return_type = fun_type.list_type.return_type # HACK UGLY
    return_type.unify body.sexp_type
    return Sexp.new(:return, body, Type.void)
  end

  ##
  # Expects an optional expression.  Processes the expression and returns the
  # void type.

  def process_scope(exp)
    return Sexp.new(:scope, Type.void) if exp.empty?

    body = process exp.shift

    return Sexp.new(:scope, body, Type.void)
  end

  ##
  # A literal string.  Returns the string and the string type.

  def process_str(exp)
    return Sexp.new(:str, exp.shift, Type.str)
  end

  ##
  # :dstr is a dynamic string.  Returns the type :str.

  def process_dstr(exp)
    out = Sexp.new(:dstr, exp.shift, Type.str)
    until exp.empty? do
      result = process exp.shift
      out << result
    end
    return out
  end

  ##
  # Empty expression. Returns the expression and the boolean type.

  def process_true(exp)
    return Sexp.new(:true, Type.bool)
  end

  ##
  # Empty expression. Returns the expression and the boolean type.

  def process_false(exp)
    return Sexp.new(:false, Type.bool)
  end

  ##
  # :const expects an expression.  Returns the type of the constant.

  def process_const(exp)
    c = exp.shift
    if c =~ /^[A-Z]/ then
      puts "class #{c}"
    else
      raise "I don't know what to do with const #{c}. It doesn't look like a class."
    end
    Type.new(:zclass)
    raise "not done yet"
  end

end

