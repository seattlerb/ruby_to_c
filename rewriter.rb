require 'sexp_processor'

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
    var = exp.shift
    else_stmt = exp.pop

    new_exp = result
    
    until exp.empty? do
      c = exp.shift
      # start a new scope and move to it
      new_exp << Sexp.new(:if)
      new_exp = new_exp.last

      assert_type c, :when
      ignored_type, vars, stmts = process(c)

      vars = vars.map { |v| Sexp.new(:call, var.deep_clone, "===", Sexp.new(:array, v))}
      if vars.size > 1 then
        new_exp << Sexp.new(:or, *vars)
      else
        new_exp << vars.first
      end
      new_exp << stmts
    end
    new_exp << else_stmt if else_stmt

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
        result = Sexp.new()
        result.unpack = true
        result << Sexp.new(:lasgn, var_name, start_value)
        result << Sexp.new(:while,
                           Sexp.new(:call,
                                    Sexp.new(:lvar, var_name),
                                    ">=",
                                    Sexp.new(:array, finish_value)),
                           Sexp.new(:block,
                                    body,
                                    Sexp.new(:lasgn,
                                             var_name,
                                             Sexp.new(:call,
                                                      Sexp.new(:lvar, var_name),
                                                      "-",
                                                      Sexp.new(:array, Sexp.new(:lit, 1))))
                                    ))
      when "upto" then
        # REFACTOR: completely duped from above and direction changed
        var.shift # 
        start_value = lhs
        finish_value = call.pop.pop # not sure about this
        var_name = var.shift
        body.find_and_replace_all(:dvar, :lvar)
        result = Sexp.new()
        result.unpack = true
        result << Sexp.new(:lasgn, var_name, start_value)
        result << Sexp.new(:while,
                           Sexp.new(:call,
                                    Sexp.new(:lvar, var_name),
                                    "<=",
                                    Sexp.new(:array, finish_value)),
                           Sexp.new(:block,
                                    body,
                                    Sexp.new(:lasgn,
                                             var_name,
                                             Sexp.new(:call,
                                                      Sexp.new(:lvar, var_name),
                                                      "+",
                                                      Sexp.new(:array, Sexp.new(:lit, 1))))
                                    ))
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

