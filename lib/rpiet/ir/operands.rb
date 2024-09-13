module RPiet
  module IR
    ##
    # Using pure Ruby types for all operands but variable:
    #   1. label => Symbol
    #   2. char => String
    #   3. numeric => Integer
    module Operands
      class VariableOperand
        attr_reader :name
        attr_accessor :value
        def initialize(name)
          @value, @name = nil, name
        end

        def eql?(other) = @name == other.name

        def hash = [self.class, @name].hash

        def to_s = "#@name#{@value ? %Q{:(#@value)} : ''}"
      end
    end
  end
end
