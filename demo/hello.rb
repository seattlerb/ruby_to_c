
class Hello
  def hello
    puts "hello world"
  end

  def main # silly hack
    hello
    return 0
  end
end
