class Environment

  attr_accessor :env

  def initialize
    @env = [{}]
  end

  def depth
    @env.length
  end

  def add(id, val, depth = 0)
    raise "Adding illegal identifier #{id.inspect}" unless Symbol === id
    @env[depth][id.to_s.sub(/^\*/, '').intern] = val
  end

  def extend
    @env.unshift({})
  end

  def unextend
    @env.shift
  end

  def lookup(id)

    warn "#{id} is a string from #{caller[0]}" if String === id

    # HACK: if id is :self, cheat for now until we have full defn remapping
    if id == :self then
      return Type.fucked
    end

    @env.each do |closure|
      return closure[id] if closure.has_key? id
    end

    raise NameError, "Unbound var: #{id.inspect} in #{@env.inspect}"
  end

  def current
    @env.first
  end

  def all
    @env.reverse.inject { |env, scope| env.merge scope }
  end

  def scope
    self.extend
    begin
      yield
    ensure
      self.unextend
    end
  end
end
