module RPiet
  module IR
    module Instructions
      class Instr
        attr_accessor :comment
        attr_reader :operands

        def operation = self.class.operation_name.to_sym
        alias :type :operation

        def initialize(*operands)
          @operands = operands
        end

        def execute(stack) = raise ArgumentError.new "Cannot execute a base class"

        def jump? = false

        def side_effect? = false

        def stack_affecting? = false

        def to_s = operation

        def self.operation_name = name.sub(/.*::/, '').sub('Instr', '').downcase
      end

      class NoopInstr < Instr
        def initialize()
          super()
        end

        def execute(stack)
        end

        def to_s = "noop"
      end

      class SingleOperandInstr < Instr
        def initialize(operand)
          super(operand)
        end

        def operand = @operands[0]

        def to_s = "#{super} #{operand}"
      end

      class SingleResultInstr < Instr
        attr_reader :result

        def initialize(result)
          super()
          @result = result
        end

        def to_s = "#{result} = #{super}"
      end

      class MathInstr < Instr
        attr_reader :oper, :result

        def initialize(oper, result, operand1, operand2)
          raise ArgumentError.new("must be numeric/variable operand.  Got: #{operand1}") unless operand1.mathy?
          raise ArgumentError.new("must be numeric/variable operand.  Got: #{operand2}") unless operand2.mathy?
          super(operand1, operand2)
          @oper, @result = oper, result
        end

        def execute(stack)
          result.value = operand1.decode.send(oper, operand2.decode)
        end

        def operand1 = @operands[0]
        def operand2 = @operands[1]

        def constant?
          operand1.kind_of?(Operands::NumericOperand) && operand2.kind_of?(Operands::NumericOperand)
        end

        def to_s = "#{result} = #{operand1} #{oper} #{operand2}"
      end

      class AddInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:+, result, operand1, operand2)
      end

      class SubInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:-, result, operand1, operand2)
      end

      class MultInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:*, result, operand1, operand2)
      end

      class DivInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:/, result, operand1, operand2)
      end

      class ModInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:%, result, operand1, operand2)
      end

      class PowInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:**, result, operand1, operand2)
      end

      class CopyInstr < Instr
        attr_reader :result

        def initialize(result, operand)
          super(operand)
          @result = result
        end

        def execute(stack)
          @result.value = operand
        end

        def operand = @operands[0]

        def to_s = "#{result} = #{super} #{operand}#{comment ? %Q{ # #{comment}} : ""}"
      end

      class LabelInstr < NoopInstr
        attr_reader :value

        def initialize(value)
          super()
          @value = value
        end

        def to_s = "#{super}(#{value})"
      end

      # input/output instructions
      class NoutInstr < SingleOperandInstr
        def execute(stack) = print operand.decode

        def side_effect? = true
      end

      class CoutInstr < SingleOperandInstr
        def execute(stack) = print operand.decode.chr

        def side_effect? = true
      end

      class NinInstr < SingleResultInstr
        def execute(stack)
          result.value = $stdin.gets.to_i
        end

        def side_effect? = true
      end

      class CinInstr < SingleResultInstr
        def execute(stack)
          result.value = $stdin.read(1).ord
        end

        def side_effect? = true
      end

      # instructions which manipulate the stack

      class PopInstr < SingleResultInstr
        def execute(stack)
          result.value = stack.pop
        end

        def side_effect? = true

        def stack_affecting? = true
      end

      class PushInstr < SingleOperandInstr
        def execute(stack) = stack.push operand.decode

        def side_effect? = true

        def stack_affecting? = true
      end

      class RollInstr < Instr
        def initialize(depth, num)
          super
        end

        def execute(stack)
          d, n = depth.decode, num.decode
          n %= d
          return if d <= 0 || num == 0
          if n > 0
            stack[-d..-1] = stack[-n..-1] + stack[-d...-n]
          elsif n < 0
            stack[-d..-1] = stack[-d...-n] + stack[-n..-1]
          end
        end

        def depth = @operands[0]
        def num = @operands[1]

        def side_effect? = true

        def stack_affecting? = true

        def to_s = "#{super}(#{depth}, #{num})"
      end

      # possible jumping instructions
      class JumpInstr < Instr
        attr_reader :label

        def initialize(label, *operands)
          super(*operands)
          @label = label
        end

        def jump? = true

        def execute(stack) = label

        alias :value :label

        # We are changing flow control so we cannot depend on stack changing without
        # flow control algo
        def stack_affecting? = true

        def to_s = "jump -> #{value}"
      end

      class TwoOperandJumpInstr < JumpInstr
        def initialize(operand1, operand2, label)
          super(label, operand1, operand2)
        end

        def operand1 = @operands[0]
        def operand2 = @operands[1]

        def to_s = "#{operand1} #{doc_syntax} #{operand2} -> #{label}"
      end

      class BEQInstr < TwoOperandJumpInstr
        def doc_syntax = "=="
        def execute(stack) = operand1.decode == operand2.decode ? super : nil
      end

      class BNEInstr < TwoOperandJumpInstr
        def doc_syntax = "!="
        def execute(stack) = operand1.decode != operand2.decode ? super : nil
      end

      class GTInstr  < TwoOperandJumpInstr
        def doc_syntax = ">"
        def execute(stack) = operand1.decode > operand2.decode ? super : nil
      end

      class NodeInstr < Instr
        attr_reader :operation, :step, :x, :y

        def initialize(operation, step, x, y)
          @operation, @step, @x, @y = operation, step, x, y
        end

        def execute(stack)
          #puts "DEBUG: #{self}"
        end

        def to_s = "node = [#{operation}, #{step}, #{x}, #{y}]"
      end
    end
  end
end