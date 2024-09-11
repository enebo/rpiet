require_relative 'instructions'
require_relative 'operands'

module RPiet
  module IR
    module ConstantPropagation
      module_function def run(instructions)
        constants = {}
        constant_instrs = {}
        dead_instrs = []

        instructions.each_with_index do |instr, i|
          puts "I: #{instr}"
          instr.operands.each_with_index do |operand, j|
            if constants[operand]
              dead_instrs << constant_instrs[operand]
              instr.operands[j] = constants[operand]
              folded_instr = fold(instr)
              if folded_instr != instr
                instructions[i] = folded_instr
                instr = folded_instr
              end
            end
          end

          case instr
          when Instructions::CopyInstr
            constants[instr.result] = instr.operand
            constant_instrs[instr.result] = instr
          end
        end

        dead_instrs.each do |instr|
          instructions.delete(instr)
        end
      end

      module_function def fold(instr)
        if instr.kind_of?(Instructions::MathInstr) && instr.constant?
          Instructions::CopyInstr.new(instr.result, instr.execute(nil))
        else
          instr
        end
      end
    end
  end
end