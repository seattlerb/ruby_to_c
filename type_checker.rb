
begin
  require 'rubygems'
  require_gem 'ParseTree'
  require 'sexp_processor'
rescue LoadError
  require 'parse_tree'
end

require 'rewriter'
require 'support'
require 'pp'

# TODO: calls to sexp_type should probably be replaced w/ better Sexp API

##
# TypeChecker bootstrap table.
#
# Default type signatures to help the TypeChecker figure out the correct types
# for methods that it might not otherwise encounter.
#
# The format is:
#   :method_name => [[:reciever_type, :args_type_1, ..., :return_type], ...]

$bootstrap = {
  :<  => [[:long, :long, :bool],],
  :<= => [[:long, :long, :bool],],
  :== => [[:long, :long, :bool],],
  :>  => [[:long, :long, :bool],],
  :>= => [[:long, :long, :bool],],

  :+  => ([
            [:long, :long, :long],
            [:str, :str, :str],
          ]),
  :-  => [[:long, :long, :long],],
  :*  => [[:long, :long, :long],],

  # polymorphics:
  :nil? => [[:value, :bool],],
  :to_s => [[:long, :str],],  # HACK - should be :value, :str
  :to_i => [[:long, :long],], # HACK - should be :value, :str
  :puts => [[:void, :str, :void],],
  :print => [[:void, :str, :void],],

  :[]   => ([
              [:long_list, :long, :long],
              [:str, :long, :long],
            ]),

  # TODO: get rid of these
  :case_equal_str => [[:str, :str, :bool],],
  :case_equal_long => [[:long, :long, :bool],],
}

##
# TypeChecker inferences types for sexps using type unification.
#
# TypeChecker expects sexps rewritten with Rewriter, and outputs TypedSexps.
#
# Nodes marked as 'unsupported' do not do correct type-checking of all the
# pieces of the node.  They generate possibly incorrect output, that is all.

class TypeChecker < SexpProcessor

  ##
  # Environment containing local variables

  attr_reader :env

  ##
  # The global environment contains global variables and constants.

  attr_reader :genv

  ##
  # Function table

  attr_reader :functions

  ##
  # Utility method that translates a class and optional method name to
  # a type checked sexp. Mostly used for testing.

  def translate(klass, method = nil)
    @@parser = ParseTree.new(false) unless defined? @@parser
    @@rewriter = Rewriter.new unless defined? @@rewriter
    sexp = @@parser.parse_tree_for_method klass, method
    sexp = @@rewriter.process sexp
    self.process sexp
  end

  ##
  # Utility method that translates a class and optional method name to
  # a type checked sexp. Mostly used for testing.

  def self.translate(klass, method = nil)
    self.new.translate(klass, method)
  end

  ##
  # Yet another utility method - this time the official one, although
  # we don't like the implementation at this stage.

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

  def initialize # :nodoc:
    super
    @env = Environment.new
    @genv = Environment.new
    @functions = FunctionTable.new
    self.auto_shift_type = true
    self.strict = true
    self.expected = TypedSexp

    bootstrap
  end

  ##
  # Runs the bootstrap stage, which runs over +$bootstrap+ and
  # converts each entry into a full fledged method signature
  # registered in the type checker. This is where the basic knowledge
  # for lower level types (in C) comes from.

  def bootstrap
    @genv.add :$stdin, Type.file
    @genv.add :$stdout, Type.file
    @genv.add :$stderr, Type.file

    ObjectSpace.each_object(Class) do |klass|
      next if klass.name =~ /::/ # only 2 classes is core, but many others
      @genv.add klass.name.intern, Type.fucked
    end

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
  # Logical and unifies its two arguments, then returns a bool sexp.

  def process_and(exp)
    rhs = process exp.shift
    lhs = process exp.shift

    rhs_type = rhs.sexp_type
    lhs_type = lhs.sexp_type

    rhs_type.unify lhs_type
    rhs_type.unify Type.bool

    return t(:and, rhs, lhs, Type.bool)
  end

  ##
  # Args list adds each variable to the local variable table with unknown
  # types, then returns an untyped args list of name/type pairs.

  def process_args(exp)
    formals = t(:args)
    types = []

    until exp.empty? do
      arg = exp.shift
      type = Type.unknown
      @env.add arg, type
      formals << t(arg, type)
      types << type
    end

    return formals
  end

  ##
	# Arg list stuff

	def process_arglist(exp)
		args = process_array exp
		args[0] = :arglist

		args
	end

  ##
  # Array processes each item in the array, then returns an untyped sexp.

  def process_array(exp)
    types = []
    vars = t(:array)
    until exp.empty? do
      var = process exp.shift
      vars << var
      types << var.sexp_type
    end
    vars
  end

  ##
  # Attrasgn processes its rhs and lhs, then returns an untyped sexp.
  #--
  # TODO rewrite this in Rewriter
  # echo "self.blah=7" | parse_tree_show -f
  # => [:attrasgn, [:self], :blah=, [:array, [:lit, 7]]]

  def process_attrasgn(exp)
    rhs = process exp.shift
    name = exp.shift
    lhs = process exp.shift

    # TODO: since this is an ivar, we need to figger out their var system. :/
    return t(:attrasgn, rhs, name, lhs)
  end

  ##
  # Begin processes the body, then returns an untyped sexp.

  def process_begin(exp)
    body = process exp.shift
    # shouldn't be anything to unify
    return t(:begin, body)
  end

  ##
  # Block processes each sexp in the block, then returns an unknown-typed
  # sexp.

  def process_block(exp)
    nodes = t(:block, Type.unknown)
    until exp.empty? do
      nodes << process(exp.shift)
    end
    nodes
  end

  ##
  # Block arg is currently unsupported.  Returns an unmentionably-typed
  # sexp.
  #--
  # TODO do something more sensible

  def process_block_arg(exp)
    t(:block_arg, exp.shift, Type.fucked)
  end

  ##
  # Block pass is currently unsupported.  Returns a typed sexp.
  #--
  # TODO: we might want to look at rewriting this into a call variation.
  # echo "class E; def e(&b); blah(&b); end; end" | parse_tree_show 
  # => [:defn, :e, [:scope, [:block, [:args], [:block_arg, :b], [:block_pass, [:lvar, :b], [:fcall, :blah]]]]]

  def process_block_pass(exp)
    block = process exp.shift
    call  = process exp.shift
    t(:block_pass, block, call)
  end

  ##
  # Call unifies the actual function paramaters against the formal function
  # paramaters, if a function type signature already exists in the function
  # table.  If no type signature for the function name exists, the function is
  # added to the function list.
  #
  # Returns a sexp returned to the type of the function return value, or
  # unknown if it has not yet been determined.

  def process_call(exp)
    lhs = process exp.shift     # can be nil
    name = exp.shift
    args = process exp.shift

    arg_types = if args.nil? then
                  []
                else
                  if args.first == :arglist then
                    args.sexp_types
                  elsif args.first == :splat then
                    [args.sexp_type]
                  else
                    raise "That's not a Ruby Sexp you handed me, I'm freaking out on: #{args.inspect}"
                  end
                end

    if name == :=== then
      rhs = args[1]
      raise "lhs of === may not be nil" if lhs.nil?
      raise "rhs of === may not be nil" if rhs.nil?
      raise "Help! I can't figure out what kind of #=== comparison to use" if
        lhs.sexp_type.unknown? and rhs.sexp_type.unknown?
      equal_type = lhs.sexp_type.unknown? ? rhs.sexp_type : lhs.sexp_type
      name = "case_equal_#{equal_type.list_type}".intern
    end

    return_type = Type.unknown
    lhs_type = lhs.nil? ? Type.unknown : lhs.sexp_type # TODO: maybe void instead of unknown

    function_type = Type.function(lhs_type, arg_types, return_type)
    @functions.unify(name, function_type) do
      @functions.add_function(name, function_type)
      $stderr.puts "\nWARNING: function #{name} called w/o being defined. Registering #{function_type.inspect}" if $DEBUG
    end
    return_type = function_type.list_type.return_type

    return t(:call, lhs, name, args, return_type)
  end

  ##
  # Class adds the class name to the global environment, processes all of the
  # methods in the class.  Returns a zclass-typed sexp.

  def process_class(exp)
    name = exp.shift
    superclass = exp.shift

    @genv.add name, Type.zclass

    result = t(:class, Type.zclass)
    result << name
    result << superclass
      
    @env.scope do
      # HACK: not sure this is the right place, maybe genv instead?
      klass = eval(name.to_s) # HACK do proper lookup - ugh
      klass.constants.each do |c|
        const_type = case klass.const_get(c)
                     when Fixnum then
                       Type.long
                     when String then
                       Type.str
                     else
                       Type.unknown
                     end
        @env.add c.intern, const_type
      end

      until exp.empty? do
        result << process(exp.shift)
      end
    end

    return result
  end

  ##
  # Colon 2 returns a zclass-typed sexp

  def process_colon2(exp) # (Module::Class/Module)
    name = exp.shift
    return t(:colon2, name, Type.zclass)
  end

  ##
  # Colon 3 returns a zclass-typed sexp

  def process_colon3(exp) # (::OUTER_CONST)
    name = exp.shift
    return t(:colon2, name, Type.const)
  end

  ##
  # Const looks up the type of the const in the global environment, then
  # returns a sexp of that type.
  #
  # Const is partially unsupported.
  #--
  # TODO :const isn't supported anywhere.

  def process_const(exp)
    c = exp.shift
    if c.to_s =~ /^[A-Z]/ then
      # TODO: validate that it really is a const?
      type = @genv.lookup(c) rescue @env.lookup(c)
      return t(:const, c, type)
    else
      raise "I don't know what to do with const #{c.inspect}. It doesn't look like a class."
    end
    raise "need to finish process_const in #{self.class}"
  end

  ##
  # Class variables are currently unsupported.  Returns an unknown-typed sexp.
  #--
  # TODO support class variables

  def process_cvar(exp)
    # TODO: we should treat these as globals and have them in the top scope
    name = exp.shift
    return t(:cvar, name, Type.unknown)
  end

  ##
  # Class variable assignment
  #--
  # TODO support class variables

  def process_cvasgn(exp)
    name = exp.shift
    val = process exp.shift
    return t(:cvasgn, name, val, Type.unknown)
  end

  ##
  # Dynamic variable assignment adds the unknown type to the local
  # environment then returns an unknown-typed sexp.

  def process_dasgn_curr(exp)
    name = exp.shift
    type = Type.unknown
    @env.add name, type # HACK lookup before adding like lasgn

    return t(:dasgn_curr, name, type)
  end

  ##
  # Defined? processes the body, then returns a bool-typed sexp.

  def process_defined(exp)
    thing = process exp.shift
    return t(:defined, thing, Type.bool)
  end

  ##
  # Defn adds the formal argument types to the local environment and attempts
  # to unify itself against the function table.  If no function exists in the
  # function table, defn adds itself.
  #
  # Defn returns a function-typed sexp.

  def process_defn(exp)
    name = exp.shift
    unprocessed_args = exp.shift
    args = body = function_type = nil

    @env.scope do
      args = process unprocessed_args

      begin
        body = process exp.shift
      rescue TypeError => err
        puts "Error in method #{name}, trying to unify, whole body blew out"
        raise
      end

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
      begin
        return_type.unify sub_exp[1].sexp_type
        return_count += 1
      rescue TypeError => err
        puts "Error in method #{name}, trying to unify #{sub_exp.inspect} against #{return_type.inspect}"
        raise
      end
    end
    if return_count == 0 then
      begin
        return_type.unify Type.void
      rescue TypeError => err
        puts "Error in method #{name}, trying to unify #{function_type.inspect} against Type.void"
        raise
      end
    end

    # TODO: bad API, clean
    raise "wrong" if
      args.sexp_types.size != function_type.list_type.formal_types.size
    args.sexp_types.each_with_index do |type, i|
      type.unify function_type.list_type.formal_types[i]
    end

    return t(:defn, name, args, body, function_type)
  end

  ##
  # Dynamic string processes all the elements of the body and returns a
  # string-typed sexp.

  def process_dstr(exp)
    out = t(:dstr, exp.shift, Type.str)
    until exp.empty? do
      result = process exp.shift
      out << result
    end
    return out
  end

  ##
  # Dynamic variable lookup looks up the variable in the local environment and
  # returns a sexp of that type.

  def process_dvar(exp)
    name = exp.shift
    type = @env.lookup name
    return t(:dvar, name, type)
  end

  ##
  # Ensure processes the res and the ensure, and returns an untyped sexp.

  def process_ensure(exp)
    res = process exp.shift
    ens = process exp.shift

    t(:ensure, res, ens)
  end

  ##
  # DOC

  def process_error(exp) # :nodoc:
    t(:error, exp.shift)
  end

  ##
  # False returns a bool-typed sexp.

  def process_false(exp)
    return t(:false, Type.bool)
  end

  ##
  # Global variable assignment gets stored in the global assignment.

  def process_gasgn(exp)
    var = exp.shift
    val = process exp.shift

    var_type = @genv.lookup var rescue nil
    if var_type.nil? then
      @genv.add var, val.sexp_type
    else
      val.sexp_type.unify var_type
    end

    return t(:gasgn, var, val, val.sexp_type)
  end

  ##
  # Global variables get looked up in the global environment.  If they are
  # found, a sexp of that type is returned, otherwise the unknown type is
  # added to the global environment and an unknown-typed sexp is returned.

  def process_gvar(exp)
    name = exp.shift
    type = @genv.lookup name rescue nil
    if type.nil? then
      type = Type.unknown
      @genv.add name, type
    end
    return t(:gvar, name, type)
  end

  ##
  # Hash (inline hashes) are not supported.  Returns an unmentionably-typed
  # sexp.
  #--
  # TODO support inline hashes

  def process_hash(exp)
    result = t(:hash, Type.fucked)
    until exp.empty? do
      result << process(exp.shift)
    end
    return result
  end

  ##
  # Instance variable assignment is currently unsupported.  Does no
  # unification and returns an untyped sexp

  def process_iasgn(exp)
    var = exp.shift
    val = process exp.shift

    var_type = @env.lookup var rescue nil
    if var_type.nil? then
      @env.add var, val.sexp_type
    else
      val.sexp_type.unify var_type
    end

    return t(:iasgn, var, val, val.sexp_type)
  end

  ##
  # If unifies the condition against the bool type, then unifies the return
  # types of the then and else expressions against each other.  Returns a sexp
  # typed the same as the then and else expressions.

  def process_if(exp)
    cond_exp = process exp.shift
    then_exp = process exp.shift
    else_exp = process exp.shift rescue nil # might be empty

    cond_exp.sexp_type.unify Type.bool
    begin
      then_exp.sexp_type.unify else_exp.sexp_type unless then_exp.nil? or else_exp.nil?
    rescue TypeError => err
      puts "Error unifying #{then_exp.inspect} with #{else_exp.inspect}"
      raise
    end

    # FIX: at least document this
    type = then_exp.sexp_type unless then_exp.nil?
    type = else_exp.sexp_type unless else_exp.nil?

    return t(:if, cond_exp, then_exp, else_exp, type)
  end

  ##
  # Iter unifies the dynamic variables against the call args (dynamic
  # variables are used in the iter body) and returns a void-typed sexp.

  def process_iter(exp)
    call_exp = process exp.shift
    dargs_exp = process exp.shift
    body_exp = process exp.shift

    lhs = call_exp[1] # FIX
    Type.unknown_list.unify lhs.sexp_type # force a list type, lhs must be Enum
    Type.new(lhs.sexp_type.list_type).unify dargs_exp.sexp_type # pull out type

    return t(:iter, call_exp, dargs_exp, body_exp, Type.void)
  end

  ##
  # Instance variables are currently unsupported.  Returns an unknown-typed
  # sexp.
  #--
  # TODO support instance variables

  def process_ivar(exp)
    name = exp.shift

    var_type = @env.lookup name rescue nil
    if var_type.nil? then
      var_type = Type.unknown
      @env.add name, var_type
    end

    return t(:ivar, name, var_type)
  end

  ##
  # Local variable assignment unifies the variable type from the environment
  # with the assignment expression, and returns a sexp of that type.  If there
  # is no local variable in the environment, one is added with the type of the
  # assignment expression and a sexp of that type is returned.

  def process_lasgn(exp)
    name = exp.shift
    arg_exp = nil
    arg_type = nil
    var_type = @env.lookup name rescue nil

    sub_exp = exp.shift
    sub_exp_type = sub_exp.first
    arg_exp = process sub_exp

   # if we've got an array in there, unify everything in it.
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

    return t(:lasgn, name, arg_exp, var_type)
  end

  ##
  # Literal values return a sexp typed to match the literal expression.

  def process_lit(exp)
    value = exp.shift
    type = nil

    case value
    when Fixnum then
      type = Type.long
    when Float then
      type = Type.float
    when Symbol then
      type = Type.symbol
    else
      raise "Bug! no: Unknown literal #{value}:#{value.class}"
    end

    return t(:lit, value, type)
  end

  ##
  # Local variables get looked up in the local environment and a sexp of that
  # type is returned.

  def process_lvar(exp)
    name = exp.shift
    t = @env.lookup name
    return t(:lvar, name, t)
  end

  ##
  # Nil returns a value-typed sexp.

  def process_nil(exp)
    # don't do a fucking thing until... we have something to do
    # HACK: wtf to do here? (what type is nil?!?!)
    return t(:nil, Type.value)
  end

  ##
  # Not unifies the type of its expression against bool, then returns a
  # bool-typed sexp.

  def process_not(exp)
    thing = process exp.shift
    thing.sexp_type.unify Type.bool
    return t(:not, thing, Type.bool)
  end

  ##
  # ||= operator is currently unsupported.  Returns an untyped sexp.
  #--
  # TODO support ||=

  def process_op_asgn_or(exp)
    ivar = process exp.shift
    iasgn = process exp.shift
    body = process exp.shift
    # TODO: probably need to unify all three? or at least the first two...
    return t(:op_asgn_or, ivar, iasgn, body)
  end

  ##
  # Or unifies the left and right hand sides with bool, then returns a
  # bool-typed sexp.

  def process_or(exp)
    rhs = process exp.shift
    lhs = process exp.shift

    rhs_type = rhs.sexp_type
    lhs_type = lhs.sexp_type

    rhs_type.unify lhs_type
    rhs_type.unify Type.bool

    return t(:or, rhs, lhs, Type.bool)
  end

  ##
  # Rescue body returns an unknown-typed sexp.

  def process_resbody(exp)
    o1 = process exp.shift
    o2 = process exp.shift
    o3 = exp.empty? ? nil : process(exp.shift)

    result = t(:resbody, Type.unknown) # void?
    result << o1
    result << o2 unless o2.nil?
    result << o3 unless o3.nil?
    
    return result
  end

  ##
  # Rescue unifies the begin, rescue and ensure types, and returns an untyped
  # sexp.
  #--
  # FIX isn't used anywhere

  def process_rescue(exp)
    # TODO: I think there is also an else stmt. Should make it
    # mandatory, not optional.
    # TODO: test me
    try_block = process exp.shift
    rescue_block = process exp.shift
    ensure_block = process exp.shift

    try_type = try_block.sexp_type
    rescue_type = rescue_block.sexp_type
    ensure_type = ensure_block.sexp_type # FIX: not sure if I should unify

    try_type.unify rescue_type
    try_type.unify ensure_type

    return t(:rescue, try_block, rescue_block, ensure_block, try_type)
  end

  ##
  # Return returns a void typed sexp.

  def process_return(exp)
    result = t(:return, Type.void) # TODO why void - cuz this is a keyword
    result << process(exp.shift) unless exp.empty?
    return result
  end

  ##
  # Scope returns a void-typed sexp.

  def process_scope(exp)
    return t(:scope, Type.void) if exp.empty?

    body = process exp.shift

    return t(:scope, body, Type.void)
  end

  ##
  # Self is currently unsupported.  Returns an unknown-typed sexp.
  #--
  # TODO support self

  def process_self(exp)
    return t(:self, Type.unknown)
  end

  ##
  # Splat is currently unsupported.  Returns an unknown-typed sexp.
  #--
  # TODO support splat, maybe like :array?

  def process_splat(exp)
    value = process exp.shift
    return t(:splat, value, Type.unknown) # TODO: probably value_list?
  end

  ##
  # String literal returns a string-typed sexp.

  def process_str(exp)
    return t(:str, exp.shift, Type.str)
  end

  ##
  # Super is currently unsupported.  Returns an unknown-typed sexp.
  #--
  # TODO support super

  def process_super(exp)
    args = process exp.shift
    # TODO try to look up the method in our superclass?
    return t(:super, args, Type.unknown)
  end

  ##
  # True returns a bool-typed sexp.

  def process_true(exp)
    return t(:true, Type.bool)
  end

  ##
  # While unifies the condition with bool, then returns an untyped sexp.

  def process_while(exp)
    cond = process exp.shift
    body = process exp.shift
    is_precondition = exp.shift
    Type.bool.unify cond.sexp_type
    return t(:while, cond, body, is_precondition)
  end

  ##
  # Yield is currently unsupported.  Returns a unmentionably-typed sexp.

  def process_yield(exp)
    result = t(:yield, Type.fucked)
    until exp.empty? do
      result << process(exp.shift)
    end
    return result
  end

end


