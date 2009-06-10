class Environment # now inherited from ruby_parser. Extends with the following:

  TYPE = 0
  VALUE = 1

  attr_reader :env

  def add(id, type, depth = 0)
    raise "Adding illegal identifier #{id.inspect}" unless
      Symbol === id
    raise ArgumentError, "type must be a valid Type instance" unless
      Type === type
    @env[depth][id.to_s.sub(/^\*/, '').intern][TYPE] = type
  end

  def depth
    @env.length
  end

  def get_val(name)
    self._get(name)[VALUE]
  end

  def lookup(name)
    # HACK: if name is :self, cheat for now until we have full defn remapping
    return Type.fucked if name == :self

    return self._get(name)[TYPE]
  end

  def set_val(name, val)
    self._get(name)[VALUE] = val
  end

  def scope
    self.extend
    begin
      yield
    ensure
      self.unextend
    end
  end

  def _get(name)
    @env.each do |closure|
      return closure[name] if closure.has_key? name
    end

    raise NameError, "Unbound var: #{name.inspect} in #{@env.inspect}"
  end
end
