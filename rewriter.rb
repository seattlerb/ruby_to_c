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

    [:call, name, lhs, args]
  end

  ##
  # Rewrites :case/:when nodes as nested :if nodes

  def process_case(exp)
    result = []
    var = exp.shift
    else_stmt = exp.pop

    new_exp = result
    
    until exp.empty? do
      c = exp.shift
      # start a new scope and move to it
      new_exp << [:if]
      new_exp = new_exp.last

      assert_type c, :when
      vars, stmts = process(c)

      vars = vars.map { |v| [:call, "===", var.deep_clone, [:array, v]]}
      if vars.size > 1 then
        new_exp << [:or, *vars ] # HACK FIX FUCK - this will break if > 2
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

    [:defn, name, args, body]
  end

  ##
  # Rewrites :fcall nodes to the unified :call format:
  # [:call, name, lhs, args]

  def process_fcall(exp)
    name = exp.shift
    args = process exp.shift

    [:call, name, nil, args]
  end

  ##
  # Rewrites :vcall nodes to the unified :call format:
  # [:call, name, lhs, args]

  def process_vcall(exp)
    name = exp.shift

    [:call, name, nil, nil]
  end

  def process_when(exp)
    vars = exp.shift
    assert_type vars, :array
    vars.shift # nuke vars type
    stmts = process(exp)
    return vars, stmts.first
  end
end

