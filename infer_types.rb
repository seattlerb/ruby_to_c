require 'parse_tree'
require 'sexp_processor'

class Handle

  attr_accessor :contents

  def initialize(contents)
    @contents = contents
  end

  def ==(other)
    return nil unless other.class == self.class
    return other.contents == self.contents
  end

end

class Type

  KNOWN_TYPES = {
    :unknown => "Unknown",
    :long => "Integer",
    :str => "String",
    :void => "Void",
    :bool => "Bool",
    :value => "Value",
  }

  TYPES = {}

  def self.method_missing(type, *args)
    raise "Unknown type #{type}" unless KNOWN_TYPES.has_key?(type)
    case type 
    when :unknown then
      return self.new(type)
    else
      TYPES[type] = self.new(type) unless TYPES.has_key?(type)
      return TYPES[type]
    end
  end

  def self.unknown_list
    self.new(:unknown, true)
  end

  attr_accessor :type
  attr_accessor :list

  def initialize(type, list=false)
    raise "Unknown type #{type.inspect}" unless KNOWN_TYPES.has_key? type
    @type = Handle.new type
    @list = list
  end

  def unknown?
    self.type.contents == :unknown
  end

  def list?
    @list
  end

  # REFACTOR: this should be named type, but that'll break code at the moment
  def list_type
    @type.contents
  end

  def ==(other)
    return nil unless other.class == self.class

    return false unless other.type == self.type
    return false unless other.list? == self.list?
    return true
  end

  def unify(other)
    return self if other == self and (not self.unknown?)

    if self.unknown? and other.unknown? then
      # link types between unknowns
      @type = other.type
      @list = other.list? or self.list? # HACK may need to be tri-state
    elsif self.unknown? then
      # other's type is now my type
      @type.contents = other.type.contents
      @list = other.list?
    elsif other.unknown? then
      # my type is now other's type
      other.type.contents = @type.contents
      other.list = self.list?
    else
      raise "Unable to unify #{self} with #{other}"
    end

    return self
  end

  def to_s
    KNOWN_TYPES[@type.contents] + "#{' list' if self.list?}"
  end

  def inspect
    "Type.#{self.type.contents}"
  end

end

class Environment

  def initialize
    @env = []
  end

  def depth
    @env.length
  end

  def add(id, val)
    @env[0][id] = val
  end

  def extend
    @env.unshift({})
  end

  def unextend
    @env.shift
  end

  def lookup(id)
    @env.each do |closure|
      return closure[id] if closure.has_key? id
    end

    raise "Unbound var #{id}"
  end

end

# this is fucked up. Stolen from Avi no less, so that explains it. ;)
class Tree

  def initialize
    @root = []
    @stack = [@root]
  end

  # the whole tree
  def root
    @root.first
  end

  # shifts onto the last item in stack,
  # which is also owned by (eventually) root
  def add(node)
    @stack.last << node
  end

  # NOTE: only popping from the stack, not from the tree.
  def pop
    @stack.pop
  end

  # This adds the node to the tree, and then pushes the node on the stack
  def push(node)
    add node
    @stack << node
  end

  alias << push

end

class InferTypes

  attr_reader :tree
  attr_reader :env

  def initialize
    @env = Environment.new
    @genv = Environment.new
    @genv.extend
    @genv.add "$stderr", :file
  end

  def augment(klass, method=nil)
    tree = Tree.new
    self.check(ParseTree.new.parse_tree(klass, method), tree)
    tree.root
  end

  protected

  def check(exp, tree)

#    p exp, @env if exp and exp.first == :defn

    if exp.nil? then
      tree.add nil
      return Type.unknown
    end

    @original = exp.deep_clone if exp.first == :defn

    node_type = exp.shift
    tree.push [node_type]

    ret_val = 
      case node_type
      # :args, :dasgn_curr expects a single variable.  Returns its type.
      when :args, :dasgn_curr then
        types = []
        until exp.empty? do
          arg = exp.shift
          typ = Type.unknown
          tree.add [arg, typ]
          @env.add arg, typ
          types << typ
        end
        types
      # :array expects list of expressions.  Returns a corresponding list of
      # types.
      when :array then
        types = []
        until exp.empty? do
          sub_exp = exp.shift
          types << check(sub_exp, tree)
        end
        types
      # :rescue expects a try and rescue block.  Unifies and returns their
      # type.
      when :rescue then
        # TODO: I think there is also an else stmt. Should make it
        # mandatory, not optional.
        # TODO: test me
        try_block = check(exp.shift, tree)
        rescue_block = check(exp.shift, tree)
        try_block.unify rescue_block
        try_block
      # :block expects a list of expressions.  Returns the type of the last
      # expression.
      when :block then
        block_type = nil
        until exp.empty? do
          sub_exp = exp.shift
          block_type = check(sub_exp, tree)
        end
        block_type
      # :call expects an lvar, a method name, and an optional array of
      # arguments.  Unifies the argumets according to the method name.
      # Returns the type of the call.
      when :call then
        lvar = check(exp.shift, tree)
        method = exp.shift
        tree.add method
        unless exp.empty? then
          rvar = check(exp.shift, tree)[0]
          case method
          when '==', 'equal?', '<', '>', '<=', '>=' then
            rvar.unify lvar
            Type.new(:bool)
          when '<=>',
            '+', '-', '*', '/', '%' then
            # HACK HACK HACK: unify rvar, :long
            # TODO: unify and use real type
            rvar.unify lvar
          when 'puts' then
            # TODO: we need to look up out of a real table of C methods
            rvar.unify Type.new(:str)
            Type.new(:void)
          else
            raise "unhandled method #{method}"
          end
        else
          case method
          when 'each' then
            lvar.unify Type.unknown_list
          when 'nil?' then
            Type.bool
          when 'to_i', 'class' then
            lvar
          when 'to_s' then
            Type.new(:str)
          else
            raise "unhandled method '#{method}'"
          end
        end
      # :case expects a test expression followed by a list of when
      # expressions and an else expression.  Unifies the when expressions
      # and the else expressions, and returns this type.
      when :case then
        # TODO add magical expression variable to environment so :when can
        # unify with it.
        expression = check(exp.shift, tree)
        body = []
        until exp.empty? do
          body << check(exp.shift, tree)
        end
      # :defn expects a method name and an expression.  Returns the return
      # type of the method.
      when :defn then
        name = exp.shift
        @env.extend
        @env.add :return, Type.unknown
        tree.add name
        check(exp.shift, tree)
        ret_type = @env.lookup :return
        ret_type = Type.void if ret_type.unknown?
        @env.unextend
        tree.add ret_type
        ret_type
      # :dvar expects a variable name. Returns the type of the variable.
      when :dvar then
        dvar = exp.shift
        tree.add dvar
        @env.lookup dvar
      # :fcall expects a method name and a list of arguments.  Returns the
      # return type of the method call.
      when :fcall then
        tree.add exp.shift
        type = check(exp.shift, tree)
        Type.unknown
      # :if expects a conditional, if branch and else branch expressions.
      # Unifies and returns the type of the three expressions.
      when :if then
        cond_type = check(exp.shift, tree)
        then_type = check(exp.shift, tree)
        else_type = check(exp.shift, tree)
        cond_type.unify Type.new(:bool)
        then_type.unify else_type
      # :iter expects a call, dargs and body expression.  Unifies the type of
      # the call and dargs expressions.  Returns the type of the body.
      when :iter then
        call_exp = exp.shift
        dargs_exp = exp.shift
        body_exp = exp.shift

        call = check(call_exp, tree)
        dargs = check(dargs_exp, tree)

        # HACK: call needs to be a list type (this may not be an actual hack)
        Type.new(call.list_type).unify dargs[0]
        body = check(body_exp, tree)
      # :lasgn expects a variable name and an expression.  Returns the type of
      # the variable.
      when :lasgn then
        name = exp.shift
        tree.add name
        name_type = @env.lookup name rescue nil
        sub_exp = exp.shift
        case sub_exp.first          
        when :array then
          arg_types = check(sub_exp, tree)
          arg_type = arg_types.inject(Type.unknown) do |t1, t2|
            t1.unify t2
          end
          arg_type.list = true
        else
          arg_type = check(sub_exp, tree)
        end

        unless name_type.nil? then
          name_type.unify arg_type
          tree.add nil
        else
          tree.add arg_type
          @env.add name, arg_type
        end

        arg_type
      # :lit is a literal value.  Returns the type of the literal.
      when :lit then
        lit = exp.shift
        tree.add lit
        case lit
        when Fixnum then
          Type.new(:long)
        else
          raise "Bug! Unknown literal type #{exp}"
        end
      # :lvar expects a variable name.  Returns the type of the variable name.
      when :lvar then
        lvar = exp.shift
        tree.add lvar
        @env.lookup lvar
      # :gvar expects a variable name.  Returns the type of the variable name.
      when :gvar then # TODO: this isn't actually global at this point
        gvar = exp.shift
        tree.add gvar
        gvar_type = @genv.lookup gvar
        if gvar_type.nil? then
          gvar_type = Type.unknown
          @genv.add name, gvar_type
        end
#        tree.add gvar_type
        gvar_type
      # :nil returns the type :nil.
      when :nil then
        # don't do a fucking thing until... we have something to do
        # HACK: wtf to do here?
        Type.new(:value)
      # :return expects an expression.  Unifies the return type with the
      # current method's return type and returns it.
      when :return then
        value = check(exp.shift, tree)
        @env.lookup(:return).unify value
      # :scope expects an expression.  Returns the type of the the expression.
      when :scope then
        @env.extend
        scope_type = check(exp.shift, tree)
        @env.unextend
        scope_type
      # :str is a literal string.  Returns the type :str.
      when :str then
        tree.add exp.shift
        Type.new(:str)
      # dstr is a dynamic string.  Returns the type :str.
      when :dstr
        tree.add exp.shift
        until exp.empty? do
          check(exp.shift, tree)
        end
        Type.new(:str)
      # :true, :false are literal booleans.  Returns the type :bool.
      when :true, :false then
        Type.new(:bool)
      # :const expects an expression.  Returns the type of the constant.
      when :const then
        c = exp.shift
        if c =~ /^[A-Z]/ then
          puts "class #{c}"
        else
          raise "I don't know what to do with const #{c}. It doesn't look like a class."
        end
        Type.new(:zclass)
      # :when expects DOC
      when :when then
        args = check(exp.shift, tree)
        body = check(exp.shift, tree)
      else
        raise "Bug! Unknown node type #{node_type.inspect} in #{([node_type] + exp).inspect}"
      end # case

    tree.pop

    raise "exp is not empty!!! #{exp.inspect} from #{@original.inspect}" unless exp.empty?

    return ret_val
  end # check

end

