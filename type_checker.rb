require 'sexp_processor'
require 'parse_tree'
require 'rewriter'
require 'support'
require 'pp'

# TODO: calls to sexp_type should probably be replaced w/ better Sexp API

$bootstrap = {
  # :sym => [[:reciever, :args, :return], ...]
  "<"  => [[:long, :long, :bool],],
  "<=" => [[:long, :long, :bool],],
  "==" => [[:long, :long, :bool],],
  ">"  => [[:long, :long, :bool],],
  ">=" => [[:long, :long, :bool],],

  "+"  => ([
             [:long, :long, :long],
             [:str, :str, :str],
           ]),
  "-"  => [[:long, :long, :long],],
  "*"  => [[:long, :long, :long],],

  # polymorphics:
  "nil?" => [[:value, :bool],],
  "to_s" => [[:long, :str],],  # HACK - should be :value, :str
  "to_i" => [[:long, :long],], # HACK - should be :value, :str
  "puts" => [[:void, :str, :void],],
  "print" => [[:void, :str, :void],],

  "[]"   => ([
               [:long_list, :long, :long],
               [:str, :long, :long],
             ]),

  # TODO: get rid of these
  "case_equal_str" => [[:str, :str, :bool],],
  "case_equal_long" => [[:long, :long, :bool],],
}

class TypeChecker < SexpProcessor

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
    @env = Environment.new
    @genv = Environment.new
    @functions = FunctionTable.new
    self.auto_shift_type = true
    self.strict = true

    bootstrap
  end

  def bootstrap
    @genv.add "$stderr", Type.file
    @genv.add "$stdout", Type.file
    @genv.add "$stdin", Type.file

    $bootstrap.each do |name,signatures|
      # FIX: Using Type.send because it must go through method_missing, not new
      signatures.each do |signature|
        lhs_type = Type.send(signature[0])
        return_type = Type.send(signature[-1])
        arg_types = signature[1..-2].map { |t| Type.send(t) }
        @functions.add_function(name, Type.function(lhs_type, arg_types, return_type))
      end
    end
  end

  ##
  # Logical and

  def process_and(exp)
    rhs = process exp.shift
    lhs = process exp.shift

    rhs_type = rhs.sexp_type
    lhs_type = lhs.sexp_type

    rhs_type.unify lhs_type
    rhs_type.unify Type.bool

    return Sexp.new(:and, rhs, lhs, Type.bool)
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
    lhs = process exp.shift     # can be nil
    name = exp.shift
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

    return_type = Type.unknown
    lhs_type = lhs.nil? ? Type.unknown : lhs.sexp_type # TODO: maybe void instead of unknown

    function_type = Type.function(lhs_type, arg_types, return_type)
    @functions.unify(name, function_type) do
      @functions.add_function(name, function_type)
      $stderr.puts "\nWARNING: function #{name} called w/o being defined. Registering #{function_type.inspect}" if $DEBUG
    end
    return_type = function_type.list_type.return_type

    return Sexp.new(:call, lhs, name, args, return_type)
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
    name = exp.shift
    unprocessed_args = exp.shift
    args = body = function_type = nil

    @env.scope do
      args = process unprocessed_args
      body = process exp.shift

      # Function might already have been defined by a :call node.
      # TODO: figure out the receiver type? Is that possible at this stage?
      function_type = Type.function Type.unknown, args.sexp_types, Type.unknown
      @functions.unify(name, function_type) do
        @functions.add_function(name, function_type)
        $stderr.puts "\nWARNING: Registering function #{name}: #{function_type.inspect}" if $DEBUG
      end
    end

    return_type = function_type.list_type.return_type

    # Drill down and find all return calls, unify each one against the
    # registered function return value. That way they all have to
    # return the same type. If we don't end up finding any returns,
    # set the function return type to void.

    return_count = 0
    body.each_of_type(:return) do |sub_exp|
      return_type.unify sub_exp[1].sexp_type
      return_count += 1
    end
    if return_count == 0 then
      return_type.unify Type.void
    end

    # TODO: bad API, clean
    raise "wrong" if
      args.sexp_types.size != function_type.list_type.formal_types.size
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

    lhs = call_exp[1] # FIX
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
  # Expects an expression.  Unifies the return type with the current method's
  # return type and returns the expression and the void type.

  def process_return(exp)
    body = process exp.shift
    return Sexp.new(:return, body, Type.void) # TODO: why void?!?
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

  # TODO: move these into alphabetical order

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

  def process_while(exp)
    cond = process exp.shift
    body = process exp.shift
    Type.bool.unify cond.sexp_type
    Sexp.new(:while, cond, body)
  end
  
end

