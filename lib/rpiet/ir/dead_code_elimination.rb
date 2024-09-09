require_relative 'instructions'
require_relative 'operands'

module RPiet
  module IR
    module DeadCodeElimination
      module_function def run(instructions)
        unresolved = {}

        loop do
          instructions.each do |instr|
            # All lhs will be a variable and until we see it used on rhs it is unresolved
            unresolved[instr.result] = instr if instr.respond_to?(:result) && !instr.side_effect?

            instr.operands.each do |operand|
              unresolved.delete(operand) if operand.kind_of?(Operands::VariableOperand)
            end
          end

          break if unresolved.empty?

          unresolved.each_value do |instr|
            instructions.delete(instr)
          end
          unresolved.clear
        end
      end
    end
  end
end