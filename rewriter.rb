require 'sexp_processor'

class Rewriter < SexpProcessor

  def process_case(exp)
    result = []
    exp.shift # nuke the type
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

      vars = vars.map { |v| [:call, var.deep_clone, "==", [:array, v]]}
      if vars.size > 1 then
        new_exp << [:or, *vars ]
      else
        new_exp << vars.first
      end
      new_exp << stmts
    end
    new_exp << else_stmt if else_stmt

    result.first
  end

  def process_when(exp)
    exp.shift # nuke type
    vars = exp.shift
    assert_type vars, :array
    vars.shift # nuke vars type
    stmts = process(exp)
    return vars, stmts.first
  end
end

