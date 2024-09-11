module RPiet
  module IR
    module Operands
      class Operand
        attr_reader :value
        def initialize(value)
          @value = value
        end

        def eql?(other) = @value == other.value

        def type = self.class.name.sub(/.*::/, '').sub('Operand', '').downcase.to_sym

        def to_s = value.to_s

        alias :decode :value
      end

      class LabelOperand < Operand
      end

      class NumericOperand < Operand
      end

      class StringOperand < Operand
      end

      class VariableOperand < Operand
        attr_reader :name
        attr_accessor :value
        def initialize(name)
          super(nil)
          @name = name
        end

        def eql?(other) = @name == other.name

        def hash = [self.class, @name].hash

        def to_s = "#@label#{@value ? %Q{: (#@value)} : ''}"
      end
    end
  end
end
