
$TESTING = false unless defined? $TESTING

begin require 'rubygems' rescue LoadError end
require 'ruby_to_ansi_c'

class RubyToRubyC < RubyToAnsiC

  ##
  # Lazy initializer for the composite RubytoC translator chain.

  def self.translator
    # TODO: FIX, but write a test first
    unless defined? @@translator then
      @@translator = CompositeSexpProcessor.new
      @@translator << Rewriter.new
      @@translator << TypeChecker.new
      @@translator << R2CRewriter.new
      @@translator << RubyToRubyC.new
      @@translator.on_error_in(:defn) do |processor, exp, err|
        result = processor.expected.new
        case result
        when Array then
          result << :error
        end
        msg = "// ERROR: #{err.class}: #{err}"
        msg += " in #{exp.inspect}" unless exp.nil? or $TESTING
        msg += " from #{caller.join(', ')}" unless $TESTING
        result << msg
        result
      end
    end
    @@translator
  end

  def initialize # :nodoc:
    super
  end
end
