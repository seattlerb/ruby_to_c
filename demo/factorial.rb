##
# Factorial demo class for Interpreter.

class Factorial

  ##
  # This is a really slow factorial implementation, but that's ok!

  def fact(n)
    acc = 1

    n.downto 1 do |i|
      acc = mult acc, i
    end

    return acc
  end

  ##
  # Expensive multiplication!  Cool!

  def mult(a, b)
    acc = 0

    a.downto 1 do |i|
      acc += b
    end

    return acc
  end

  ##
  # This is a faster factorial implementation.

  def fast_fact(n)
    acc = 1

    n.downto 1 do |i|
      acc *= i
    end

    return acc
  end

  def main # :nodoc:
    n = 5

    fast = fast_fact(n)
    #puts "fast: #{fast}" # only with interp.rb

    slow = fact(n)
    #puts "slow: #{slow}" # only with interp.rb

    if fast == slow and fast == 120 then
      puts "pass"
    else
      puts "fail"
    end

    return slow
  end

end

