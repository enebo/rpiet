require_relative '../asg/parser'
require_relative 'builder'
require_relative 'cfg'
require_relative 'passes/peephole'

module RPiet
  module IR
    class IRInterpreter
      include LiveMachineState

      def initialize(image_or_instructions, event_handler = nil)
        handle_event_handler(@event_handler = event_handler)

        if image_or_instructions.kind_of?(RPiet::Image::Image)
          process_image(image_or_instructions)
        else
          @instructions = image_or_instructions
        end

        @jump_table = calculate_jump_table(@instructions) # {label -> index}
        reset
      end

      def process_image(image)
        graph = RPiet::ASG::Parser.new(image).run
        builder = RPiet::Builder.new
        builder.run graph
        @instructions = builder.instructions
        puts "simple ir # of instr: #{@instructions.length}"
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
        i = 0
        while i < instructions.length
          instr = instructions[i]

          if instr.operation == :label
            jump_table[instr.operand] = i
            instructions.delete(instr)
          else
            i += 1
          end
        end
        jump_table
      end

      def next_instruction_logging
        instr = @instructions[@ipc]

        if instr&.graph_node && @last_node != instr.graph_node
          @last_node = instr.graph_node
          @event_handler.operation(self, @last_node.step, @last_node.operation)
        end

        @event_handler.instruction(self, instr)
        instr
      end

      def next_instruction
        @instructions[@ipc]
      end

      def next_step
        value = next_instruction.execute(self)

        if value
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

      private def handle_event_handler(event_handler)
        if event_handler
          alias next_instruction_orig next_instruction
          alias next_instruction next_instruction_logging
        end
      end
    end
  end
end