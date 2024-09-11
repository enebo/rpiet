require_relative '../asg/parser'
require_relative 'builder'

module RPiet
  module IR
    class IRInterpreter
      attr_reader :stack

      def initialize(image, event_handler=RPiet::Logger::NoOutput.new)
        @event_handler = event_handler
        # FIXME: should pass only insructions into the interp
        if image.kind_of?(RPiet::Image::Image)
          graph = RPiet::ASG::Parser.new(image).run
          builder = RPiet::Builder.new
          builder.run graph
          @instructions = builder.instructions
        else
          @instructions = image
        end

        @jump_table = calculate_jump_table(@instructions) # {label -> index}
        reset
      end

      def reset
        @ipc, @stack = 0, []
      end

      def calculate_jump_table(instructions)
        jump_table = {}
        instructions.each_with_index do |instr, i|
          jump_table[instr] = i if instr.kind_of? RPiet::IR::Instructions::LabelInstr
        end
        jump_table
      end

      def next_step
        instr = @instructions[@ipc]
        return false unless instr
        @event_handler.instruction(self, instr)
        value = instr.execute(@stack)
        if instr.jump? && value
          @ipc = @jump_table[value]
        else
          @ipc += 1
        end
        true
      end

      def run
        while next_step do
        end
      end
    end
  end
end