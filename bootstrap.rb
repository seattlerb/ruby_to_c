class TypeChecker
  class Bootstrap

    def ==(rhs, lhs)
      rhs = lhs = 1
      return true
    end

    def <(rhs, lhs)
      rhs = lhs = 1
      return true
    end

    def >=(rhs, lhs)
      rhs = lhs = 1
      return true
    end

    def <=(rhs, lhs)
      rhs = lhs = 1
      return true
    end

    def +(rhs, lhs)
      rhs = lhs = 1
      return 1
    end

    def *(rhs, lhs)
      rhs = lhs = 1
      return 1
    end

    def nil?(rhs)
      rhs = nil
      return true
    end

    def to_s(rhs)
      rhs = 1
      return "str"
    end

    def print(arg)
      arg = "string"
    end

    def puts(arg)
      arg = "string"
    end

    def case_equal_str(rhs, lhs)
      rhs = lhs = "foo"
      return true
    end

    def case_equal_long(rhs, lhs)
      rhs = lhs = 1
      return true
    end

  end
end

