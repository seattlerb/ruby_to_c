require 'typed_sexp_processor'
require 'parse_tree'

class Rewriter < SexpProcessor

  def initialize
    super
    self.auto_shift_type = true
  end

  ##
  # Rewrites :call nodes to the unified :call format:
  # [:call, name, lhs, args]

  def process_call(exp)
    lhs = process exp.shift
    name = exp.shift
    args = process exp.shift

    Sexp.new(:call, lhs, name, args)
  end

  ##
  # Rewrites :case/:when nodes as nested :if nodes

  def process_case(exp)
    result = Sexp.new
    var = process exp.shift
    else_stmt = process exp.pop

    new_exp = result
    
    until exp.empty? do
      c = exp.shift
      # start a new scope and move to it
      new_exp << Sexp.new(:if)
      new_exp = new_exp.last

      assert_type c, :when
      ignored_type, vars, stmts = process(c)

      vars = vars.map { |v| Sexp.new(:call,
                                     var.deep_clone,
                                     "===",
                                     Sexp.new(:array, process(v)))}
      if vars.size > 1 then
        new_exp << Sexp.new(:or, *vars)
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
  # [:defn, name, args, body]

  def process_defn(exp)
    name = exp.shift
    args = nil
    body = process exp.shift

    if body[1].first == :args then
      args = body[1]
      body.delete_at 1
    elsif body.last[1].first == :args then
      args = body.last[1]
      body.last.delete_at 1
    else
      raise "Unknown :defn format"
    end

    Sexp.new(:defn, name, args, body)
  end

  ##
  # Rewrites :fcall nodes to the unified :call format:
  # [:call, name, lhs, args]

  def process_fcall(exp)
    name = exp.shift
    args = process exp.shift

    Sexp.new(:call, nil, name, args)
  end

  ##
  # Rewrites specific :iter nodes into while loops:
  # [DOC]

  def process_iter(exp)
    call = process exp.shift
    var  = process exp.shift
    body = process exp.shift

    assert_type call, :call

    if call[2] != "each" then # TODO: fix call[1] (api)
      call.shift # :call
      lhs = call.shift
      method_name = call.shift

      case method_name
      when "downto" then
        var.shift # 
        start_value = lhs
        finish_value = call.pop.pop # not sure about this
        var_name = var.shift
        body.find_and_replace_all(:dvar, :lvar)

        # HACK have to pack body in case it was unpacked
        while_body = s(:block)
        if Sexp === body.first then
          until body.empty? do
            while_body << body.shift
          end
        else
          while_body << body
        end
        while_body << s(:lasgn, var_name,
                        s(:call, s(:lvar, var_name), "-",
                          s(:array, Sexp.new(:lit, 1))))

        result = s()
        result.unpack = true
        result << s(:lasgn, var_name, start_value)
        result << s(:while,
                    s(:call, s(:lvar, var_name), ">=",
                      s(:array, finish_value)),
                    while_body)
      when "upto" then
        # REFACTOR: completely duped from above and direction changed
        var.shift # 
        start_value = lhs
        finish_value = call.pop.pop # not sure about this
        var_name = var.shift
        body.find_and_replace_all(:dvar, :lvar)

        # HACK have to pack body incase it was unpacked
        while_body = s(:block)
        if Sexp === body.first then
          until body.empty? do
            while_body << body.shift
          end
        else
          while_body << body
        end
        while_body << s(:lasgn, var_name,
                        s(:call, s(:lvar, var_name), "+",
                          s(:array, Sexp.new(:lit, 1))))

        result = s()
        result.unpack = true
        result << s(:lasgn, var_name, start_value)
        result << s(:while,
                    s(:call, s(:lvar, var_name), "<=",
                      s(:array, finish_value)),
                    while_body)
      else
        raise "unknown iter method #{method_name}"
      end
    else
      Sexp.new(:iter, call, var, body)
    end
  end

  ##
  # Rewrites :vcall nodes to the unified :call format:
  # [:call, name, lhs, args]

  def process_vcall(exp)
    name = exp.shift

    Sexp.new(:call, nil, name, nil) # TODO: never has any args?
  end

  ##
  # Rewrites :when nodes so :case can digest it into if/else structure
  # [:when, [args], body]

  def process_when(exp)
    vars = exp.shift
    assert_type vars, :array
    vars.shift # nuke vars type
    stmts = process(exp)
    return Sexp.new(:when, vars, stmts.first)
  end
end

class R2CRewriter < SexpProcessor

  REWRITES = {
    [Type.str, "+", Type.str] => proc { |l,n,r|
      t(:call, nil, "strcat", r.unshift(r.shift, l), Type.str)
    }
  }

  def initialize
    super
    self.auto_shift_type = true
    self.expected = TypedSexp
  end

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
               TypedSexp.new(:call, lhs, name, rhs, exp.sexp_type)
             end

    return result
  end
end
