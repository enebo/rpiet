module RPiet
  module IR
    module Instructions
      class Instr
        # for debugging so we can print out the node to compare against the graph interpreter
        attr_accessor :graph_node
        attr_accessor :comment
        attr_reader :operands

        def operation = self.class.operation_name.to_sym
        alias :type :operation

        def initialize(*operands)
          @operands = operands
        end

        def constant? = false

        def disasm = "#{operation}!!!!"

        def execute(machine) = raise ArgumentError.new "Cannot execute a base class"

        def jump? = false

        def side_effect? = false

        def stack_affecting? = false

        def to_s = operation
        def to_s_comment = comment ? " # #{comment}" : ""

        def self.operation_name = name.sub(/.*::/, '').sub('Instr', '').downcase
        def step = graph_node.step


        def decode(machine, operand)
          case operand
          when Operands::Poperand then machine.stack.pop
          when Operands::VariableOperand then operand.value
          else operand
          end
        end

        def disasm_operand(operand)
          operand = operand.name if operand.kind_of?(Operands::VariableOperand)
          operand.to_s
        end
      end

      class NoopInstr < Instr
        def initialize()
          super()
        end

        def disasm = operation

        def execute(machine) = nil

        def to_s = "noop"
      end

      class ExitInstr < Instr
        def jump? = true

        def execute(machine) = :exit

        def to_s = "exit"
      end

      class SingleOperandInstr < Instr
        def initialize(operand) = super(operand)

        def disasm = "#{operation} #{disasm_operand(operand)}"

        def operand = @operands[0]

        def to_s = "#{operation} #{operand}"
      end

      class SingleResultInstr < Instr
        attr_reader :result

        def initialize(result)
          super()
          @result = result
        end

        def disasm = "#{result.name} = #{operation}"

        def to_s = "#{result} = #{operation}"
      end

      class MathInstr < Instr
        attr_reader :oper, :result

        def initialize(oper, result, operand1, operand2)
          raise ArgumentError.new("must be numeric/variable operand.  Got: #{operand1}") unless mathy?(operand1)
          raise ArgumentError.new("must be numeric/variable operand.  Got: #{operand2}") unless mathy?(operand2)
          super(operand1, operand2)
          @oper, @result = oper, result
        end

        def disasm = "#{result.name} = #{disasm_operand(operand1)} #{@oper} #{disasm_operand(operand2)}"

        def execute(machine)
          value2, value1 = decode(machine, operand2), decode(machine, operand1)
          result.value = value1.send(oper, value2)
          nil
        end

        def constant?
          operand1.kind_of?(Integer) && operand2.kind_of?(Integer)
        end

        def mathy?(operand)
          operand.kind_of?(Integer) || operand.kind_of?(Operands::VariableOperand)
        end

        def operand1 = @operands[0]
        def operand2 = @operands[1]

        def to_s = "#{result} = #{operand1} #{oper} #{operand2}"
      end

      class AddInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:+, result, operand1, operand2)
      end

      class SubInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:-, result, operand1, operand2)

        def two_pop = Sub2PopInstr.new(result)
      end

      class MultInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:*, result, operand1, operand2)
      end

      class DivInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:/, result, operand1, operand2)

        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          result.value = b == 0 ? DIV_BY_ZERO_VALUE : a / b
          nil
        end

        def two_pop = Div2PopInstr.new(result)
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

        def disasm = "#{disasm_operand(result)} = #{operation} #{disasm_operand(operand)}"

        def execute(machine)
          @result.value = decode(machine, operand)
          nil
        end

        def operand = @operands[0]

        def to_s = "#{result} = #{operation} #{operand}#{comment ? %Q{ # #{comment}} : ""}"
      end

      class LabelInstr < NoopInstr
        attr_reader :value

        def initialize(value)
          super()
          raise ArgumentError.new "label instr must have a label operand.  Got: #{value}" unless value.kind_of?(Symbol)
          @value = value
        end

        def disasm = "#{operation} #{disasm_operand(value)}"

        def operand = @value

        def to_s = "#{operation}(#{value})"
      end

      # input/output instructions
      class NoutInstr < SingleOperandInstr
        def execute(machine) = print decode(machine, operand)

        def side_effect? = true
      end

      class CoutInstr < SingleOperandInstr
        def execute(machine) = print decode(machine, operand).chr

        def side_effect? = true
      end

      class NinInstr < SingleResultInstr
        def execute(machine)
          machine.output.print "Enter an integer: "
          result.value = machine.input.gets.to_i
          machine.output.puts
          nil
        end

        def side_effect? = true
      end

      class CinInstr < SingleResultInstr
        def execute(machine)
          machine.output.print "> "
          result.value = machine.input.read(1).ord
          nil
        end

        def side_effect? = true
      end

      # instructions which manipulate the stack

      class PopInstr < SingleResultInstr
        def execute(machine)
          result.value = machine.stack.pop
          nil
        end

        def side_effect? = true

        def stack_affecting? = true
      end

      class PushInstr < SingleOperandInstr
        def execute(machine)
          machine.stack.push decode(machine, operand)
          nil
        end

        def side_effect? = true

        def stack_affecting? = true
      end

      class RollInstr < Instr
        def initialize(depth, num)
          super
        end

        def execute(machine)
          d, n = decode(machine, depth), decode(machine, num)
          n %= d
          return if d <= 0 || num == 0
          stack = machine.stack
          if n > 0
            stack[-d..-1] = stack[-n..-1] + stack[-d...-n]
          elsif n < 0
            stack[-d..-1] = stack[-d...-n] + stack[-n..-1]
          end
          nil
        end

        def depth = @operands[0]
        def num = @operands[1]

        def disasm = "#{operation} #{disasm_operand(depth)} #{disasm_operand(num)}"

        def constant? = depth.kind_of?(Integer) && num.kind_of?(Integer)

        def side_effect? = true

        def stack_affecting? = true

        def to_s = "#{operation}(#{depth}, #{num})"

        def two_pop = Roll2PopInstr.new
      end

      # possible jumping instructions
      class JumpInstr < Instr
        attr_reader :label

        def initialize(label, *operands)
          super(*operands)
          @label = label
        end

        def disasm = "#{operation} #{value}"

        def jump? = true

        def execute(machine) = label

        alias :value :label

        # We are changing flow control so we cannot depend on stack changing without
        # flow control algo
        def stack_affecting? = true

        def to_s = "jump -> #{value}#{to_s_comment}"
      end

      class TwoOperandJumpInstr < JumpInstr
        def initialize(operand1, operand2, label)
          super(label, operand1, operand2)
        end

        def disasm = "#{disasm_operand(operand1)} #{doc_syntax} #{disasm_operand(operand2)} #{label}"

        def operand1 = @operands[0]
        def operand2 = @operands[1]

        def constant?
          operand1.kind_of?(Integer) && operand2.kind_of?(Integer)
        end

        def to_s = "#{operand1} #{doc_syntax} #{operand2} -> #{label}"
      end

      class BEQInstr < TwoOperandJumpInstr
        def doc_syntax = "=="
        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          a == b ? super : nil
        end
      end

      class BNEInstr < TwoOperandJumpInstr
        def doc_syntax = "!="
        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          a != b ? super : nil
        end
      end

      class GTInstr < Instr
        attr_reader :result
        def initialize(result, *operands)
          super(*operands)
          @result = result
        end

        def operand1 = operands[0]
        def operand2 = operands[1]

        def constant? = operand1.kind_of?(Integer) && operand2.kind_of?(Integer)

        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          result.value = a > b ? 1 : 0
          nil
        end

        def to_s = "#{result} = #{operand1} > #{operand2}"
      end

      class NEInstr < Instr
        attr_reader :result
        def initialize(result, *operands)
          super(*operands)
          @result = result
        end

        def operand1 = operands[0]
        def operand2 = operands[1]

        def constant? = operand1.kind_of?(Integer) && operand2.kind_of?(Integer)

        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          result.value = a != b ? 0 : 1
          nil
        end

        def to_s = "#{result} = #{operand1} > #{operand2}"
      end

      class DPInstr < SingleOperandInstr
        def execute(machine)
          machine.dp.from_ordinal!(decode(machine, operand))
          nil
        end
      end

      class CCInstr < SingleOperandInstr
        def execute(machine)
          machine.cc.from_ordinal!(decode(machine, operand))
          nil
        end
      end

      class DPRotateInstr < SingleOperandInstr
        attr_reader :result
        def initialize(result, operand)
          super(operand)
          @result = result
        end

        def execute(machine)
          machine.dp.rotate!(decode(machine, operand))
          result.value = machine.dp.dup
          nil
        end

        def to_s = "#{result} = #{operation} #{operand}"
      end

      class CCToggleInstr < SingleOperandInstr
        attr_reader :result
        def initialize(result, operand)
          super(operand)
          @result = result
        end

        def execute(machine)
          machine.cc.switch!(decode(machine, operand))
          result.value = machine.cc.dup
          nil
        end

        def to_s = "#{result} = #{operation} #{operand}"
      end
    end
  end
end