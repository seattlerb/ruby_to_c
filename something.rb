
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
    puts(arg3)
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
    $stderr.puts(var2)
    return var2
  end

  def interpolated
    var = 14
    var2 = "var is #{var}. So there."
  end
end
