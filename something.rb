
class Something

  # basically: do we work at all?
  def empty
  end

  # First order transformation: basic language constructs
  def stupid
    return nil
  end

  def simple(arg1)
    print arg1
    puts((4 + 2).to_s)
  end

  def global
    $stderr.fputs("blah")
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
      puts(x.to_s)
    end
  end

  def iteration2
    array = [1, 2, 3]
    array.each { |x| puts(x.to_s) }
  end

  def iteration3
    array1 = [1, 2, 3]
    array2 = [4, 5, 6, 7]
    array1.each do |x|
      array2.each do |y|
	puts(x.to_s)
	puts(y.to_s)
      end
    end
  end

  def iteration4
    1.upto(3) do |n|
      puts n.to_s
    end
  end

  def iteration5
    3.downto(1) do |n|
      puts n.to_s
    end
  end

  def case_stmt
    var = 2
    result = ""
    case var
    when 1 then
      # block
      puts "something"
      result = "red"
    when 2, 3 then
      result = "yellow"
    when 4 then
      # nothing
    else
      result = "green"
    end

    case result
    when "red" then
      var = 1
    when "yellow" then
      var = 2
    when "green" then
      var = 3
    end

    return result
  end

  # Other edge cases:

  def multi_args(arg1, arg2)
    arg3 = arg1 * arg2 * 7
    puts(arg3.to_s)
    return "foo"
  end

  def bools(arg1)
    unless arg1.nil? then
      return true
    else
      return false
    end
  end

  def eric_is_stubborn
    var = 42
    var2 = var.to_s
    $stderr.fputs(var2)
    return var2
  end

  def interpolated
    var = 14
    var2 = "var is #{var}. So there."
  end

  def unknown_args(arg1, arg2)
    # does nothing
    return arg1
  end

  def determine_args
    5 == unknown_args(4, "known")
  end

end
