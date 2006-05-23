class Environment

  TYPE = 0
  VALUE = 1

  attr_reader :env

  def initialize
    @env = []
    self.extend
  end

  def add(id, type, depth = 0)
    raise "Adding illegal identifier #{id.inspect}" unless Symbol === id
    raise ArgumentError, "type must be a valid Type instance" unless Type === type
    @env[depth][id.to_s.sub(/^\*/, '').intern][TYPE] = type
  end

  def all
    @env.reverse.inject { |env, scope| env.merge scope }
  end

  def current
    @env.first
  end

  def depth
    @env.length
  end

  def extend
    @env.unshift(Hash.new { |h,k| h[k] = [] })
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

  def unextend
    @env.shift
    raise "You went too far unextending env" if @env.empty?
  end

  def _get(name)
    @env.each do |closure|
      return closure[name] if closure.has_key? name
    end

    raise NameError, "Unbound var: #{name.inspect} in #{@env.inspect}"
  end
end
