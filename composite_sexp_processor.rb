require 'sexp_processor'

class CompositeSexpProcessor < SexpProcessor

  attr_reader :processors

  def initialize(*processors)
    super
    @processors = []
  end

  def <<(processor)
    raise ArgumentError, "Can only add sexp processors" unless
      SexpProcessor === processor
    @processors << processor
  end

  def process(exp)
    @processors.each do |processor|
      exp = processor.process(exp)
    end
    exp
  end
end
