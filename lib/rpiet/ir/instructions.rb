module RPiet
  module IR
    module Instructions
      class Instr
        def operation
          self.class.operation_name.to_sym
        end
        alias :name :operation

        def execute(stack)
          raise ArgumentError.new "Cannot execute a base class"
        end

        def jump?
          false
        end

        def to_s
          operation
        end

        def self.operation_name
          name.sub(/.*::/, '').sub('Instr', '').downcase
        end
      end

      class NoopInstr < Instr
        def execute(stack)
        end
      end

      class SingleOperandInstr < Instr
        attr_reader :operand

        def initialize(operand)
          @operand = operand
        end

        def to_s
          "#{name}(#{operand}}"
        end
      end

      class SingleResultInstr < Instr
        attr_reader :result

        def initialize(result)
          @result = result
        end

        def to_s
          "#{result} = #{name}"
        end
      end

      class MathInstr < Instr
        attr_reader :oper, :result, :operand1, :operand2

        def initialize(oper, result, operand1, operand2)
          @oper, @result, @operand1, @operand2 = oper, result, operand1, operand2
        end

        def execute(stack)
          result.encode = operand1.decode.send(oper, operand2.decode)
        end

        def to_s
          "#{result} = #{operand1} #{oper} #{operand2}"
        end
      end

      class AddInstr < MathInstr
        def initialize(result, operand1, operand2); super(:+, result, operand1, operand2); end
      end

      class SubInstr < MathInstr
        def initialize(result, operand1, operand2); super(:-, result, operand1, operand2); end
      end

      class MultInstr < MathInstr
        def initialize(result, operand1, operand2); super(:*, result, operand1, operand2); end
      end

      class DivInstr < MathInstr
        def initialize(result, operand1, operand2); super(:/, result, operand1, operand2); end
      end

      class ModInstr < MathInstr
        def initialize(result, operand1, operand2); super(:%, result, operand1, operand2); end
      end

      class PowInstr < MathInstr
        def initialize(result, operand1, operand2); super(:**, result, operand1, operand2); end
      end

      class CopyInstr < Instr
        attr_reader :result, :operand

        def initialize(result, operand)
          @result, @operand = result, operand
        end

        def execute(stack)
          @result.encode = operand.decode
        end

        def to_s
          "#{result} = #{name} #{operand}"
        end
      end

      class LabelInstr < NoopInstr
        attr_reader :value

        def initialize(value)
          @value = value
        end

        def to_s
          "#{name}(#{value})"
        end
      end

      # input/output instructions
      class NoutInstr < SingleOperandInstr
        def execute(stack)
          print operand.decode
        end
      end

      class CoutInstr < SingleOperandInstr
        def execute(stack)
          print operand.decode.chr
        end
      end

      class NinInstr < SingleResultInstr
        def execute(stack)
          result.encode = $stdin.gets.to_i
        end
      end

      class CinInstr < SingleResultInstr
        def execute(stack)
          result.encode = $stdin.read(1).ord
        end
      end

      # instructions which manipulate the stack

      class PopInstr < SingleResultInstr
        def execute(stack)
          result.encode = stack.pop
        end
      end

      class PushInstr < SingleOperandInstr
        def execute(stack)
          stack.push operand.decode
        end
      end

      class RollInstr < Instr
        attr_reader :depth, :num

        def initialize(depth, num)
          @depth, @num = depth, num
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

        def to_s
          "#{name}(#{depth}, #{num})"
        end
      end

      # possible jumping instructions
      class JumpInstr < LabelInstr

        def jump?
          true
        end

        def execute(stack)
          label
        end

        alias :label :value

        def to_s
          "#{name} -> #{value}"
        end
      end

      class TwoOperandJumpInstr < JumpInstr
        attr_reader :operand1, :operand2

        def initialize(operand1, operand2, label)
          super(label)
          @operand1, @operand2 = operand1, operand2
        end

        def to_s
          "#{operand1} #{doc_syntax} #{operand2} -> #{label}"
        end
      end

      class BEQInstr < TwoOperandJumpInstr
        def doc_syntax; "=="; end
        def execute(stack)
          return super if operand1.decode == operand2.decode
          nil
        end
      end

      class BNEInstr < TwoOperandJumpInstr
        def doc_syntax; "!="; end
        def execute(stack)
          return super if operand1.decode != operand2.decode
          nil
        end
      end

      class GTInstr  < TwoOperandJumpInstr
        def doc_syntax; ">"; end
        def execute(stack)
          return super if operand1.decode > operand2.decode
          nil
        end
      end

      class NodeInstr < Instr
        attr_reader :operation, :step, :x, :y

        def initialize(operation, step, x, y)
          @operation, @step, @x, @y = operation, step, x, y
        end

        def execute(stack)
          #puts "DEBUG: #{self}"
        end

        def to_s
          "node = [#{operation}, #{step}, #{x}, #{y}]"
        end
      end
    end
  end
end