require 'sexp_processor'
require 'parse_tree'
require 'rewriter'
require 'support'

class TypeChecker < SexpProcessor

  require 'bootstrap'

  attr_reader :tree
  attr_reader :env
  attr_reader :genv
  attr_reader :functions

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

    bootstrap
  end

  def bootstrap
    @genv.extend
    @genv.add "$stderr", Type.file

    parser = ParseTree.new
    rewriter = Rewriter.new
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
    return [:args], [] if exp.empty?
    formals = []
    types = []

    until exp.empty? do
      arg = exp.shift
      type = Type.unknown
      @env.add arg, type
      formals << [arg, type]
      types << type
    end

    return [:args, *formals], types
  end

  ##
  # Expects list of expressions.  Returns a corresponding list of
  # expressions and types.

  def process_array(exp)
    types = []
    vars = []
    until exp.empty? do
      var, type = process exp.shift
      vars << var
      types << type
    end
    return [:array, *vars], types
  end

  ##
  # Expects a list of expressions.  Processes each expression and
  # returns the unknown type.

  def process_block(exp)
    nodes = []
    until exp.empty? do
      body, type = process exp.shift
      nodes << body
    end
    return [:block, *nodes], Type.unknown
  end

  ##
  # Expects a function name, an optional lhs, and an optional
  # list of arguments.
  #
  # Unifies the arguments according to the method name.

  def process_call(exp)
    name = exp.shift
    rhs, rhs_type = process exp.shift
    args, arg_types = process exp.shift

    if name == "===" then
      equal_type = nil
      if rhs_type.unknown? and lhs_type.unknown? then
        raise "Help! I can't figure out what kind of #=== comparison to use"
      elsif not rhs_type.unknown? then
        equal_type = rhs_type
      else
        equal_type = lhs_type
      end

      name = "case_equal_#{equal_type.list_type}"
    end

    function_type = @functions[name]
    return_type = Type.unknown

    arg_types = [] if arg_types.nil?
    unless rhs_type.nil? then
      arg_types.unshift rhs_type
    end

    if function_type.nil?  then
      @functions[name] = Type.function arg_types, return_type
    else
      function_type.unify Type.function(arg_types, return_type)
      return_type = function_type.list_type.return_type
    end

    return [:call, name, rhs, args], return_type
  end

  ##
  # Expects a single variable.  Returns the expression and the unknown type.

  def process_dasgn_curr(exp)
    name = exp.shift
    type = Type.unknown
    @env.add name, type

    return [:dasgn_curr, name, type], type
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

    args, arg_types = process exp.shift
    unless @functions.has_key? name then
      @functions[name] = Type.function arg_types, return_type
    end
    body, body_type = process exp.shift

    @env.unextend
    @current_function_name = nil

    function_type = @functions[name]

    return_type.unify Type.void if return_type == Type.unknown

    arg_types.each_with_index do |type, i|
      type.unify function_type.list_type.formal_types[i]
    end

    return [:defn, name, args, body, function_type], function_type
  end

  ##
  # Expects a variable name.  Returns the expression and variable type.

  def process_dvar(exp)
    name = exp.shift
    type = @env.lookup name
    return [:dvar, name, type], type
  end

  ##
  # :if expects a conditional, if branch and else branch expressions.
  # Unifies and returns the type of the three expressions.

  def process_if(exp)
    cond_exp, cond_type = process exp.shift
    then_exp, then_type = process exp.shift
    else_exp, else_type = process exp.shift
    cond_type.unify Type.bool
    then_type.unify else_type unless then_exp.nil? or else_exp.nil?
    type = then_type unless then_type.nil?
    type = else_type unless else_type.nil?

    return [:if, cond_exp, then_exp, else_exp], type
  end

  ##
  # Extracts the type of the rhs from the call expression and
  # unifies it with a list type.  Then unifies the type of the
  # rhs with the dynamic arg and then processes the body.
  # 
  # Returns the expression and the void type.

  def process_iter(exp)
    call_exp = exp.shift

    rhs = call_exp[2].deep_clone
    rhs, rhs_type = process rhs

    list_type = Type.unknown_list
    list_type.unify rhs_type

    call_exp, call_type = process call_exp
    dargs_exp, dargs_type = process exp.shift

    Type.new(rhs_type.list_type).unify dargs_type
    body_exp, body_type = process exp.shift

    return [:iter, call_exp, dargs_exp, body_exp], Type.void
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
    case sub_exp.first
    when :array then
      arg_exp, arg_type = process sub_exp
      arg_type = arg_type.inject(Type.unknown) do |t1, t2|
        t1.unify t2
      end
      arg_type = arg_type.dup # singleton type
      arg_type.list = true
    else
      arg_exp, arg_type = process sub_exp
    end

    if var_type.nil? then
      @env.add name, arg_type
      var_type = arg_type
    else
      var_type.unify arg_type
    end

    return [:lasgn, name, arg_exp, var_type], var_type
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

    return [:lit, value], type
  end

  ##
  # Expects a variable name.  Returns the expression and variable type.

  def process_lvar(exp)
    name = exp.shift
    type = @env.lookup name
    
    return [:lvar, name, type], type
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
    return [:gvar, name, type], type
  end

  ##
  # Empty expression. Returns the expression and the value type.

  def process_nil(exp)
    # don't do a fucking thing until... we have something to do
    # HACK: wtf to do here?
    return [:nil], Type.value
  end

  def process_or(exp)
    rhs, rhs_type = process exp.shift
    lhs, lhs_type = process exp.shift

    rhs_type.unify lhs_type
    rhs_type.unify Type.bool

    return [:or, rhs, lhs], Type.bool
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
    body, type = process exp.shift
    fun_type = @functions[@current_function_name]
    raise "Definition of #{@current_function_name.inspect} not found in function list" if fun_type.nil?
    return_type = fun_type.list_type.return_type # HACK UGLY
    return_type.unify type
    return [:return, body], Type.void
  end

  ##
  # Expects an optional expression.  Processes the expression and returns the
  # void type.

  def process_scope(exp)
    return [:scope], Type.void if exp.empty?

    body, = process exp.shift

    return [:scope, body], Type.void
  end

  ##
  # A literal string.  Returns the string and the string type.

  def process_str(exp)
    return [:str, exp.shift], Type.str
  end

  ##
  # :dstr is a dynamic string.  Returns the type :str.

  def process_dstr(exp)
    out = [:dstr, exp.shift]
    until exp.empty? do
      result, type = process exp.shift
      out << result
    end
    return out, Type.str
  end

  ##
  # Empty expression. Returns the expression and the boolean type.

  def process_true(exp)
    return [:true], Type.bool
  end

  ##
  # Empty expression. Returns the expression and the boolean type.

  def process_false(exp)
    return [:false], Type.bool
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

