module RPiet
  module IR
    module Operands
      class NumOperand
        attr_reader :value
        def initialize(value); @value = value; end
        def name; :num; end
        def to_s; "#{name}(#{value})"; end

        alias :decode :value
      end
      class StringOperand
        attr_reader :value
        def initialize(value); @value = value; end
        def name; :string; end
        def to_s; "#{name}(#{value})"; end

        alias :decode :value
      end
      class VariableOperand
        attr_accessor :value
        def initialize(name); @name = name; end
        def name; @name; end
        def to_s; "#@name:(#@value)" end

        alias :decode :value
        alias :encode= :value=
      end
    end
  end
end
