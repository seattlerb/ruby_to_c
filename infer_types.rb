require 'parse_tree'

# REFACTOR: dup code
class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

module Unify

  SIMPLE_TYPES = [ :str, :nil, :bool, :long ]

  def make_unknown
    [:unknown]
  end

  # DEAR GOD I HATE THIS METHOD
  def type_of(typ)
    if SIMPLE_TYPES.include?(typ) or
       (Array === typ and
        (typ[0] == :list or
         typ[0] == :unknown)) then
      typ
    elsif typ == :unknown then
      [typ]
    else
      type_of typ[0]
    end
  end

  def end_of(list)
    if Array === list and Array === list[1] then
      end_of list[1]
    else
      list
    end
  end

  def go_postal(x)
    if Array === x && x[0] == :list then
      raise "stupid: #{x.inspect}" unless Array === x[1]
    end
  end

  def unify(l1, l2)

    ret = nil

    t1 = type_of l1
    t2 = type_of l2

    go_postal(t1)
    go_postal(t2)

    if t1 == t2 then
      ret = t1
    elsif Symbol === t1 and Symbol === t2 and t1 != t2 then
      raise "Unable to unify types #{t1.inspect} and #{t2.inspect}"
    elsif t1 == make_unknown then
      t1[0] = t2
      ret = t2
    elsif t2 == make_unknown then
      t2[0] = t1
      ret = t1
    # THIS IS HORRID OO DESIGN
    elsif Array === t1 and Array === t2 and :list == t1[0] and :list == t2[0] then
      ret = [:list, unify(t1[1][0], t2[1][0])]
    else
      raise "We shouldn't be here!: #{t1.inspect}, #{t2.inspect}"
    end

    return ret
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

  include Unify

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
      return make_unknown
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
          typ = make_unknown
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
        unify try_block, rescue_block
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
          rvar = check(exp.shift, tree)
          case method
          when '==', 'equal?' then
            rvar = rvar[0]
            unify lvar, rvar
            :bool
          when '<', '>', '<=', '>=', '<=>',
            '+', '-', '*', '/', '%' then
            rvar = rvar[0]
            # HACK HACK HACK: unify rvar, :long
            # TODO: unify and use real type
            unify lvar, rvar
          when 'puts' then
            # TODO: we need to look up out of a real table of C methods
            unify rvar, :str
            :nil
          else
            raise "unhandled method #{method}"
          end
        else
          case method
          when 'each' then
            unify lvar, [:list, [make_unknown]]
          when 'nil?', 'to_i', 'class' then
            lvar
          when 'to_s' then
            :str
          else
            raise "unhandled method '#{method}'"
          end
        end
      # :defn expects a method name and an expression.  Returns the return
      # type of the method.
      when :defn then
        name = exp.shift
        @env.extend
        @env.add :return, make_unknown
        tree.add name
        check(exp.shift, tree)
        ret_type = @env.lookup :return
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
        make_unknown
      # :if expects a conditional, if branch and else branch expressions.
      # Unifies and returns the type of the three expressions.
      when :if then
        cond_type = check(exp.shift, tree)
        then_type = check(exp.shift, tree)
        else_type = check(exp.shift, tree)
        unify then_type, else_type 
      # :iter expects a call, dargs and body expression.  Unifies the type of
      # the call and dargs expressions.  Returns the type of the body.
      when :iter then
        call_exp = exp.shift
        dargs_exp = exp.shift
        body_exp = exp.shift

        call = check(call_exp, tree)
        dargs = check(dargs_exp, tree)
        unify call[1], dargs[0]
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
          arg_type = arg_types.inject make_unknown do |t1, t2|
            unify t1, t2
          end
          
          arg_type = [:list, [arg_type]]
        else
          arg_type = [check(sub_exp, tree)]
        end

        unless name_type.nil? then
          unify name_type, arg_type
        end

        tree.add arg_type

        @env.add name, arg_type

        arg_type
      # :lit is a literal value.  Returns the type of the literal.
      when :lit then
        lit = exp.shift
        tree.add lit
        case lit
        when Fixnum then
          :long
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
          gvar_type = make_unknown
          @genv.add name, gvar_type
        end
        tree.add gvar_type
        gvar_type
      # :nil returns the type :nil.
      when :nil then
        # don't do a fucking thing until... we have something to do
        :nil
      # :return expects an expression.  Unifies the return type with the
      # current method's return type and returns it.
      when :return then
        value = check(exp.shift, tree)
        unify @env.lookup(:return), value
      # :scope expects an expression.  Returns the type of the the expression.
      when :scope then
        @env.extend
        scope_type = check(exp.shift, tree)
        @env.unextend
        scope_type
      # :str is a literal string.  Returns the type :str.
      when :str then
        tree.add exp.shift
        :str
      # dstr is a dynamic string.  Returns the type :str.
      when :dstr
        $stderr.puts "WARNING: dstr not supported, stripping nodes: #{exp.inspect}"
        exp.clear
        :str
      # :true, :false are literal booleans.  Returns the type :bool.
      when :true, :false then
        :bool
      # :const expects an expression.  Returns the type of the constant.
      when :const
        c = exp.shift
        if c =~ /^[A-Z]/ then
          puts "class #{c}"
        else
          raise "I don't know what to do with const #{c}. It doesn't look like a class."
        end
        :zclass
      else
        raise "Bug! Unknown node type #{node_type.inspect} in #{([node_type] + exp).inspect}"
      end # case

    tree.pop

    raise "exp is not empty!!! #{exp.inspect} from #{@original.inspect}" unless exp.empty?

    return ret_val
  end # check

end

