
begin
  require 'rubygems'
  require_gem 'ParseTree'
rescue LoadError
  require 'parse_tree'
end

require 'typed_sexp_processor'

##
# Rewriter (probably should be renamed) is a first-pass filter that
# normalizes some of ruby's ASTs to make them more processable later
# in the pipeline. It only has processors for what it is interested
# in, so real the individual methods for a better understanding of
# what it does.

class Rewriter < SexpProcessor

  def initialize # :nodoc:
    super
    self.auto_shift_type = true
    self.unsupported = [ :cfunc, ]
    # self.debug[:defn] = /method/ # coolest debugging feature ever
  end

  ##
  # Rewrites :call nodes to the unified :call format:
  # [:call, name, lhs, args]

  def process_call(exp)
    lhs = process exp.shift
    name = exp.shift
    args = process exp.shift

    s(:call, lhs, name, args)
  end

  ##
  # Rewrites :case/:when nodes as nested :if nodes.

  def process_case(exp)
    result = s()
    var = process exp.shift
    else_stmt = process exp.pop

    new_exp = result
    
    until exp.empty? do
      c = exp.shift
      # start a new scope and move to it
      new_exp << s(:if)
      new_exp = new_exp.last

      assert_type c, :when
      ignored_type, vars, stmts = process(c)

      vars = vars.map { |v| s(:call,
                              var.deep_clone,
                              :===,
                              s(:array, process(v)))}
      if vars.size > 1 then
        new_exp << s(:or, *vars)
      else
        new_exp << vars.first
      end
      new_exp << stmts
    end
    new_exp << else_stmt

    result.first
  end

  ##
  # Rewrites :defn nodes to pull the functions arguments to the top:
  #
  # Input:
  #
  #   [:defn, name, [:scope, [:block, [:args, ...]]]]
  #   [:defn, name, [:ivar, name]]
  #   [:defn, name, [:attrset, name]]
  #
  # Output:
  #
  #   [:defn, name, args, body]

  def process_defn(exp)
    name = exp.shift
    args = s(:args)
    body = process exp.shift

    case body.first
    when :scope then
      args = body.last[1]
      assert_type args, :args
      assert_type body, :scope
      assert_type body[1], :block
      body.last.delete_at 1
    when :bmethod then
      # BEFORE: [:defn, :bmethod_added, [:bmethod, [:dasgn_curr, :x], ...]]
      # AFTER:  [:defn, :bmethod_added, [:args, :x], [:scope, [:block, ...]]]
      body.shift # :bmethod
      # [:dasgn_curr, :x],
      # [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]]
      dasgn = body.shift
      assert_type dasgn, :dasgn_curr
      dasgn.shift # type
      args.push(*dasgn)
      body.find_and_replace_all(:dvar, :lvar)
      if body.first.first == :block then
        body = s(:scope, body.shift)
      else
        body = s(:scope, s(:block, body.shift)) # single statement
      end
    when :dmethod
      # BEFORE: [:defn, :dmethod_added, [:dmethod, :bmethod_maker, ...]]
      # AFTER:  [:defn, :dmethod_added, ...]
      body = body[2][1][2] # UGH! FIX
      args = body[1]
      body.delete_at 1
      body = s(:scope, body)
    when :ivar then
      body = s(:scope, s(:block, s(:return, body)))
    when :attrset then
      argname = body.last
      args << :arg
      body = s(:scope, s(:block, s(:return, s(:iasgn, argname, s(:lvar, :arg)))))
    else
      raise "Unknown :defn format: #{name.inspect} #{args.inspect} #{body.inspect}"
    end

    return s(:defn, name, args, body)
  end

  ##
  # Rewrites :fcall nodes to the unified :call format:
  # [:call, name, lhs, args]

  def process_fcall(exp)
    name = exp.shift
    args = process exp.shift

    return s(:call, nil, name, args)
  end

  ##
  # I'm not really sure what this is for, other than to guarantee that
  # there are 4 elements in the sexp.

  def process_if(exp)
    cond = process exp.shift
    t = process(exp.shift) || nil # FIX: nil is bad, we need to switch to dummy
    f = process(exp.shift) || nil
    return s(:if, cond, t, f)
  end

  ##
  # Rewrites specific :iter nodes into while loops:
  # [DOC]

  def process_iter(exp)
    call = process exp.shift
    var  = process exp.shift
    body = process exp.shift

    if var.nil? then
      var = s(:lvar, :temp_var1) # HACK Use Unique
    end

    assert_type call, :call

    if call[2] != :each then # TODO: fix call[n] (api)
      call.shift # :call
      lhs = call.shift
      method_name = call.shift

      case method_name
      when :downto then
        var.shift # 
        start_value = lhs
        finish_value = call.pop.pop # not sure about this
        var_name = var.shift
        body.find_and_replace_all(:dvar, :lvar)
        result = s(:dummy,
                   s(:lasgn, var_name, start_value),
                   s(:while,
                     s(:call, s(:lvar, var_name), :>=,
                       s(:array, finish_value)),
                     s(:block,
                       body,
                       s(:lasgn, var_name,
                         s(:call, s(:lvar, var_name), :-,
                           s(:array, s(:lit, 1)))))))
      when :upto then
        # REFACTOR: completely duped from above and direction changed
        var.shift # 
        start_value = lhs
        finish_value = call.pop.pop # not sure about this
        var_name = var.shift
        body.find_and_replace_all(:dvar, :lvar)
        result = s(:dummy,
                   s(:lasgn, var_name, start_value),
                   s(:while,
                     s(:call, s(:lvar, var_name), :<=,
                       s(:array, finish_value)),
                     s(:block,
                       body,
                       s(:lasgn, var_name,
                         s(:call, s(:lvar, var_name), :+,
                           s(:array, s(:lit, 1)))))))
      when :define_method then
        # BEFORE: [:iter, [:call, nil, :define_method, [:array, [:lit, :bmethod_added]]], [:dasgn_curr, :x], [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]
        # we want to get it rewritten for the scope/block context, so:
        #   - throw call away
        #   - rewrite to args
        #   - plop body into a scope
        # AFTER:  [:block, [:args, :x], [:call, [:lvar, :x], :+, [:array, [:lit, 1]]]]
        var.find_and_replace_all(:dasgn_curr, :args)
        body.find_and_replace_all(:dvar, :lvar)
        result = s(:block, var, body)
      else
        raise "unknown iter method #{method_name}"
      end
    else
      s(:iter, call, var, body)
    end
  end

  ##
  # Rewrites until nodes into while nodes.

  def process_until(exp)
    cond = process s(:not, exp.shift)
    body = process exp.shift
    s(:while, cond, body)
  end

  ##
  # Rewrites :vcall nodes to the unified :call format:
  # [:call, name, lhs, args]

  def process_vcall(exp)
    name = exp.shift

    s(:call, nil, name, nil) # TODO: never has any args?
  end

  ##
  # Rewrites :when nodes so :case can digest it into if/else structure
  # [:when, [args], body]

  def process_when(exp)
    vars = exp.shift
    assert_type vars, :array
    vars.shift # nuke vars type
    stmts = process(exp)
    return s(:when, vars, stmts.first)
  end

  ##
  # Rewrites :zarray nodes to :array with no args.

  def process_zarray(exp)
    return s(:array)
  end

end

##
# R2CRewriter (should probably move this out to its own file) does
# rewritings that are language specific to C.

class R2CRewriter < SexpProcessor

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

