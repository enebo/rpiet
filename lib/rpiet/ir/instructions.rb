module RPiet
  module IR
    module Instructions
      class Instr
        # for debugging so we can print out the node to compare against the graph interpreter
        attr_accessor :graph_node, :comment
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

        def noop? = self.kind_of?(NoopInstr)

        def to_ruby(cfg, bb) = raise ArgumentError.new "missing to_ruby impl"
        def to_s = operation.to_s
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
        def ruby_operand(operand)
          case operand
          when Operands::Poperand then "@stack.pop"
          when Operands::VariableOperand then operand.name
          when Symbol then ":" + operand
          when Integer then operand
          when String  then "'#{operand}'"
          when DirectionPointer then "DirectionPointer.from_ordinal(#{operand})"
          else operand
          end
        end

        def ruby_indent(string, indent='  ')
          string.split("\n").map {|line| indent + line + "\n"}.join('')
        end
      end

      module ResultInstr
        attr_reader :result

        def initialize(result, *operands)
          super(*operands)
          @result = result
        end

        def disasm = "#{result.name} = #{operation}"

        def to_s = "#{result} = #{operation}"
      end

      module TwoOperands
        def operand1 = @operands[0]
        def operand2 = @operands[1]

        def constant?
          operand1.kind_of?(Integer) && operand2.kind_of?(Integer)
        end

        def stack_independent?
          (operand1.kind_of?(Integer) || operand1.kind_of?(Operands::VariableOperand)) ||
            (operand2.kind_of?(Integer) || operand2.kind_of?(Operands::VariableOperand))
        end

        def ruby_assign_2
          #          if operand1.kind_of?(Operands::Poperand) && operand2.kind_of?(Operands::Poperand)
          #  "b, a = @stack.pop(2)"
          #else
            "b, a = #{ruby_operand(operand2)}, #{ruby_operand(operand1)}"
          #end
        end
      end

      class NoopInstr < Instr
        def initialize
          super
        end

        def disasm = operation
        def execute(machine) = nil
        def to_ruby(cfg, bb) = "# noop\n"
        def to_s = "noop"
      end

      class ExitInstr < Instr
        def execute(machine) = :exit
        def jump? = true
        def to_ruby(cfg, bb) = "return :exit\n"
        def to_s = "exit"
      end

      class SingleOperandInstr < Instr
        def initialize(operand) = super(operand)

        def disasm = "#{operation} #{disasm_operand(operand)}"
        def operand = @operands[0]

        def to_s = "#{operation} #{operand}"
      end

      class MathInstr < Instr
        include TwoOperands
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

        def mathy?(operand)
          operand.kind_of?(Integer) || operand.kind_of?(Operands::VariableOperand)
        end

        def to_ruby(cfg, bb)
          if stack_independent?
            "  #{ruby_operand(result)} = #{ruby_operand(operand1)} #{oper} #{ruby_operand(operand2)}\n"
          else
            ruby_indent <<~"EOS"
              #{ruby_assign_2}
              #{ruby_operand(result)} = a #{oper} b
           EOS
          end
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

        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          result.value = b == 0 ? DIV_BY_ZERO_VALUE : a / b
          nil
        end
      end

      class ModInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:%, result, operand1, operand2)
      end

      class PowInstr < MathInstr
        def initialize(result, operand1, operand2) = super(:**, result, operand1, operand2)
      end

      class CopyInstr < Instr
        include ResultInstr

        def operand = @operands[0]

        def disasm = super + " #{disasm_operand(operand)}"

        def execute(machine)
          result.value = decode(machine, operand)
          nil
        end

        def to_ruby(cfg, bb) = "#{ruby_operand(result)} = #{ruby_operand(operand)}\n"
        def to_s = super + " #{operand}#{comment ? %Q{ # #{comment}} : ""}"
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

        def to_ruby(cfg, bb) = nil
        def to_s = "#{operation}(#{value})"
      end

      # input/output instructions
      class NoutInstr < SingleOperandInstr
        def execute(machine) = print decode(machine, operand)
        def to_ruby(cfg, bb) = "  print #{ruby_operand(operand)}\n"
      end

      class CoutInstr < SingleOperandInstr
        def execute(machine) = print decode(machine, operand).chr
        def to_ruby(cfg, bb) = "  print #{ruby_operand(operand)}.chr\n"
      end

      class NinInstr < Instr
        include ResultInstr

        def execute(machine)
          machine.output.print "Enter an integer: "
          result.value = machine.input.gets.to_i
          machine.output.puts
          nil
        end
        def to_ruby(cfg, bb) = ruby_indent <<~"EOS"
          output.print "Enter an integer: "
          #{ruby_operand(result)} = input.gets.to_i
          output.puts
        EOS
      end

      class CinInstr < Instr
        include ResultInstr

        def execute(machine)
          machine.output.print "> "
          result.value = machine.input.read(1).ord
          nil
        end

        def to_ruby(cfg, bb) = ruby_indent <<~"EOS"
          output.print "> "
          #{ruby_operand(result)} = input.read(1).ord
        EOS
      end

      # instructions which manipulate the stack

      class PopInstr < Instr
        include ResultInstr

        def execute(machine)
          result.value = machine.stack.pop
          nil
        end

        def to_ruby(cfg, bb) = "  #{ruby_operand(result)} = @stack.pop\n"
      end

      class PushInstr < SingleOperandInstr
        def execute(machine)
          machine.stack.push decode(machine, operand)
          nil
        end
        def to_ruby(cfg, bb) = "  @stack.push #{ruby_operand(operand)}\n"
      end

      class RollInstr < Instr
        include TwoOperands
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

        def to_ruby(cfg, bb) = ruby_indent <<~"EOS"
          d, n = #{ruby_operand(depth)}, #{ruby_operand(num)}
          n %= d
          if d > 0 && num != 0
            if n > 0
              @stack[-d..-1] = @stack[-n..-1] + @stack[-d...-n]
            elsif n < 0
              @stack[-d..-1] = @stack[-d...-n] + @stack[-n..-1]
            end
          end
        EOS

        def to_s = "#{operation}(#{depth}, #{num})"
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

        def to_ruby(cfg, bb) = "  return #{label}\n"
        def to_s = "jump -> #{value}#{to_s_comment}"
      end

      class TwoOperandJumpInstr < JumpInstr
        include TwoOperands

        def initialize(operand1, operand2, label)
          super(label, operand1, operand2)
        end

        def disasm = "#{disasm_operand(operand1)} #{doc_syntax} #{disasm_operand(operand2)} #{label}"

        def to_s = "#{operand1} #{doc_syntax} #{operand2} -> #{label}"
      end

      class BEQInstr < TwoOperandJumpInstr
        def doc_syntax = "=="
        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          a == b ? super : nil
        end
        def to_ruby(cfg, bb)
          if stack_independent?
            "  #{ruby_operand(operand1)} == #{ruby_operand(operand2)} ? :\"#{label}\" : #{cfg.outgoing_target(bb, :fall_through)&.label}\n"
          else
            ruby_indent <<~"EOS"
              #{ruby_assign_2}
              return a == b ? :"#{label}" : :"#{cfg.outgoing_target(bb, :fall_through)&.label}"
            EOS
          end
        end
      end

      class BNEInstr < TwoOperandJumpInstr
        def doc_syntax = "!="
        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          a != b ? super : nil
        end
        def to_ruby(cfg, bb)
          if stack_independent?
            "  #{ruby_operand(operand1)} != #{ruby_operand(operand2)} ? :\"#{label}\" : #{cfg.outgoing_target(bb, :fall_through)&.label}\n"
          else
            ruby_indent <<~"EOS"
              #{ruby_assign_2}
              return a != b ? :"#{label}" : :"#{cfg.outgoing_target(bb, :fall_through)&.label}"
            EOS
          end
        end
      end

      class GTInstr < Instr
        include ResultInstr, TwoOperands

        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          result.value = a > b ? 1 : 0
          nil
        end

        def disasm = "#{disasm_operand(result)} = #{disasm_operand(operand1)} > #{disasm_operand(operand2)}"

        def to_ruby(cfg, bb)
          if stack_independent?
            "  #{ruby_operand(result)} = #{ruby_operand(operand1)} > #{ruby_operand(operand2)} ? 1 : 0\n"
          else
            ruby_indent <<~"EOS"
              #{ruby_assign_2}
              #{ruby_operand(result)} = a > b ? 1 : 0
           EOS
          end
        end
      end

      class NEInstr < Instr
        include ResultInstr, TwoOperands

        def disasm = "#{disasm_operand(result)} = #{disasm_operand(operand1)} != #{disasm_operand(operand2)}"

        def execute(machine)
          b, a = decode(machine, operand2), decode(machine, operand1)
          result.value = a != b ? 0 : 1
          nil
        end

        def to_ruby(cfg, bb)
          if stack_independent?
            "  #{ruby_operand(result)} = #{ruby_operand(operand1)} != #{ruby_operand(operand2)} ? 0 : 1\n"
          else
            ruby_indent <<~"EOS"
              #{ruby_assign_2}
              #{ruby_operand(result)} = a != b ? 0 : 1
           EOS
          end
        end

        def to_s = "#{result} = #{operand1} > #{operand2}"
      end

      class DPInstr < SingleOperandInstr
        def execute(machine)
          machine.dp.from_ordinal!(decode(machine, operand))
          nil
        end
        def to_ruby(cfg, bb)
          if operand.kind_of?(Numeric) && operand >= 0 && operand < 4
            direction = DirectionPointer.new(operand)
            "  @dp.direction = Direction::#{direction.as_constant}\n"
          else
            "  @dp.from_ordinal!(#{ruby_operand(operand)})\n"
          end
        end
      end

      class CCInstr < SingleOperandInstr
        def execute(machine)
          machine.cc.from_ordinal!(decode(machine, operand))
          nil
        end
        def to_ruby(cfg, bb)
          if operand.kind_of?(Numeric) && (operand == -1 || operand == 1)
            cc = CodelChooser.new
            cc.switch!(operand)
            "  @cc.direction = CodelChooser::#{cc.as_constant}\n"
          else
            "  @cc.from_ordinal!(#{ruby_operand(operand)})\n"
          end
        end
      end

      class DPRotateInstr < SingleOperandInstr
        include ResultInstr

        def execute(machine)
          machine.dp.rotate!(decode(machine, operand))
          result.value = machine.dp.dup
          nil
        end

        def to_ruby(cfg, bb) = "  #{ruby_operand(result)} = @dp.rotate!(#{ruby_operand(operand)})\n"

        def to_s = "#{result} = #{operation} #{operand}"
      end

      class CCToggleInstr < SingleOperandInstr
        include ResultInstr

        def execute(machine)
          machine.cc.switch!(decode(machine, operand))
          result.value = machine.cc.dup
          nil
        end

        def to_ruby(cfg, bb) = "  #{ruby_operand(result)} = @cc.switch!(#{ruby_operand(operand)})\n"

        def to_s = super + " #{operand}"
      end

      class PntrInstr < Instr
        def initialize(step)
          super()
          @step = step
        end

        def execute(machine)
          operands[decode(machine, operands.first).ordinal+1]
        end

        def jump? = true

        def to_ruby_pre
          "@Operands#{@step} = [#{operands[1..-1].map { |o| ":#{o}"}.join(', ')}]\n"
        end

        def to_s = "#{operation} #{operands.first}"

        def to_ruby(cfg, bb) = "  @Operands#{@step}[#{ruby_operand(operands.first)}.ordinal]\n"
      end

      class MultiplePushInstr < Instr
        def to_ruby(cfg, bb) = "  @stack.push #{operands.map {|o| ruby_operand(o)}.join(', ')}\n"
      end

      class MultiplePopInstr < Instr
        def to_ruby(cfg, bb)
          count = operands.size

          "  #{operands.map {|o| ruby_operand(o)}.join(', ')} = @stack.pop(#{count})\n"
        end
      end
    end
  end
end