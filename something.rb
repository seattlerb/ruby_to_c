class Something
  def empty
  end

  def simple(arg1)
    print arg1
    puts 4 + 2
  end

  def conditional(arg1)
    if arg1 then
      2
    elsif arg1.nil?
      3
    else
      4
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

end
