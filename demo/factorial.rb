class F
  def factorial(n)
    f = 1
    n.downto(2) { |x| f *= x }
    return f
  end

  def main # horrid but funny hack
    return factorial(5)
  end
end
