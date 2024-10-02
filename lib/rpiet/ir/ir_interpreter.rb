require_relative '../asg/parser'
require_relative 'builder'
require_relative 'cfg'
require_relative 'passes/peephole'

module RPiet
  module IR
    class IRInterpreter
      include LiveMachineState

      def initialize(image, event_handler=RPiet::Logger::NoOutput.new)
        @event_handler = event_handler
        # FIXME: should pass only insructions into the interp
        if image.kind_of?(RPiet::Image::Image)
          graph = RPiet::ASG::Parser.new(image).run
          builder = RPiet::Builder.new
          builder.run graph
          @instructions = builder.instructions
          puts "simple ir # of instr: #{@instructions.length}"
        else
          @instructions = image
        end

        @jump_table = calculate_jump_table(@instructions) # {label -> index}
        reset
      end

      def disasm
        @instructions.each do |instr|
          puts instr.disasm
        end
      end

      def reset
        reset_machine
        @ipc, @last_node = 0, nil
      end

      def calculate_jump_table(instructions)
        jump_table = {}
        instructions.each_with_index do |instr, i|
          # We go one past label since label instructions just mark a new region of instructions
          jump_table[instr.operand] = i + 1 if instr.operation == :label
        end
        jump_table
      end

      def next_instruction
        instr = @instructions[@ipc]

        if instr&.graph_node && @last_node != instr.graph_node
          @last_node = instr.graph_node
          @event_handler.operation(self, @last_node.step, @last_node.operation)
        end

        @event_handler.instruction(self, instr)
        instr
      end

      def next_step
        instr = next_instruction
        value = instr.execute(self)

        if instr.jump? && value
          # FIXME: Make normative exit jump so it makes an exit bb vs randomly exiting (also removes this code)
          return false if value == :exit
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