require_relative '../asg/parser'
require_relative 'builder'

module RPiet
  module IR
    class IRInterpreter
      def initialize(image, event_handler=RPiet::Logger::NoOutput.new)
        @event_handler = event_handler
        graph = RPiet::ASG::Parser.new(image).run
        builder = RPiet::Builder.new
        builder.run graph
        @instructions = builder.instructions
        @stack = []
        @jump_table = calculate_jump_table(@instructions) # {label -> index}
      end

      def calculate_jump_table(instructions)
        jump_table = {}
        instructions.each_with_index do |instr, i|
          jump_table[instr] = i if instr.kind_of? RPiet::IR::Instructions::LabelInstr
        end
        jump_table
      end

      def run
        ipc = 0
        loop do
          instr = @instructions[ipc] || break
          @event_handler.instruction(self, instr)
          value = instr.execute(@stack)
          if instr.jump? && value
            ipc = @jump_table[value]
          else
            ipc += 1
          end
        end
      end
    end
  end
end