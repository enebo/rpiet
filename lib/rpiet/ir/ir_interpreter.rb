require_relative '../parser/parser'
require_relative 'builder'

module RPiet
  module IR
    class IRInterpreter
      def initialize(image, event_handler=RPiet::Logger::NoOutput.new, print)
        @event_handler = event_handler
        graph = RPiet::Parser.new(image).run
        graph.print if print == :graph || print == :all
        builder = RPiet::Builder.new
        builder.print if print == :ir || print == :all
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
        i = 0
        loop do
          instr = @instructions[i]
          break unless instr  # nil represent end of execution
          @event_handler.instruction(self, instr)
          value = instr.execute(@stack)
          if instr.jump? && value
            i = @jump_table[value]
          else
            i += 1
          end
        end
      end
    end
  end
end