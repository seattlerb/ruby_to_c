require 'sexp_processor'

class Rewriter < SexpProcessor

  def rewrite(exp)
    $stderr.puts "WARNING: this method is deprecated, use process(exp)"
    process(exp)
  end

  def process_case(exp)
    result = []
    exp.shift # nuke the type
    var = exp.shift
    else_stmt = exp.pop

    new_exp = result
    
    until exp.empty? do
      sub_exp = exp.shift
      # start a new scope and move to it
      new_exp << [:if]
      new_exp = new_exp.last    # grab the last element for the else block

      assert_type(:when, sub_exp)
      vars, stmts = process(sub_exp)

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
    vars.shift # nuke type
    stmts = process(exp.shift)
    return vars, stmts
  end
end

