
class Something
  def empty
  end

  def stupid
    return nil
  end

  def simple(arg1)
    print arg1
    puts 4 + 2
  end

  def global
    $stderr.puts("blah")
  end

  def lasgn_call
    c = 2 + 3
  end

  def conditional1(arg1)
    if arg1 == 0 then
      return 1
    end
  end

  def conditional2(arg1)
    unless arg1 == 0 then
      return 2
    end
  end

  def conditional3(arg1)
    if arg1 == 0 then
      return 3
    else
      return 4
    end
  end

  def conditional4(arg1)
    if arg1 == 0 then
      return 2
    elsif arg1 < 0 then
      return 3
    else
      return 4
    end
  end

  def iteration1
    array = [1, 2, 3]
    array.each do |x|
      puts x
    end
  end

  def iteration2
    array = [1, 2, 3]
    array.each { |x| puts x }
  end

  def iteration3
    array1 = [1, 2, 3]
    array2 = [4, 5, 6, 7]
    array1.each do |x|
      array2.each do |y|
	puts x
	puts y
      end
    end
  end

  def multi_args(arg1, arg2)
    puts(arg1 * arg2)
    return "foo"
  end

  def bools(arg1)
    unless arg1.nil? then
      return true
    else
      return false
    end
  end

end
