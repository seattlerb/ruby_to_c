class FunctionTable

  def initialize
    @functions = Hash.new do |h,k|
      h[k] = []
    end
  end

  def cheat(name) # HACK: just here for debugging
    puts "\n# WARNING: FunctionTable.cheat called from #{caller[0]}" if $DEBUG
    @functions[name]
  end

  def [](name) # HACK: just here for transition
    puts "\n# WARNING: FunctionTable.[] called from #{caller[0]}" if $DEBUG
    @functions[name].first
  end

  def has_key?(name) # HACK: just here for transition
    puts "\n# WARNING: FunctionTable.has_key? called from #{caller[0]}" if $DEBUG
    @functions.has_key?(name)
  end

  def add_function(name, type)
    @functions[name] << type
    type
  end

  def unify(name, type)
    success = false
    @functions[name].each do |o| # unify(type)
      begin
        o.unify type
        success = true
      rescue
        # ignore
      end
    end
    unless success then
      yield(name, type) if block_given?
    end
    type
  end

end
