
class Misc
  def assert(cond, n)
    if (!cond) then
      puts("-- SymTab fatal error ")
      case (n)
      when 3 
        puts("-- too many nodes in graph")
      when 4
        puts("-- too many sets")
      when 6
        puts("-- too many symbols")
      when 7
        puts("-- too many character classes")
      end
      # puts("Stack Trace = #{caller.join "\n"}")
      exit(n)
    end
  end

  def main
    assert(1 == 1, 3)
    return 0
  end
end
