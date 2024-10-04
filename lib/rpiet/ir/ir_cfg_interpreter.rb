require_relative '../asg/parser'
require_relative 'builder'
require_relative 'cfg'
require_relative 'passes/peephole'
require_relative 'passes/push_pop_elimination_pass'

module RPiet
  module IR
    class IRCFGInterpreter
      include LiveMachineState

      def initialize(image, event_handler=RPiet::Logger::NoOutput.new)
        @event_handler = event_handler
        # FIXME: should pass only insructions into the interp
        if image.kind_of?(RPiet::Image::Image)
          graph = RPiet::ASG::Parser.new(image).run
          builder = RPiet::Builder.new
          builder.run graph
          @instructions = builder.instructions
          puts "(initial) # of instr: #{@instructions.length}"
          @cfg = CFG.new(@instructions)
          #push_pop_elim = Passes::PushPopEliminationProblem.new(@cfg)
          #push_pop_elim.debug = true
          #push_pop_elim.run
          #@cfg.cull
          passes = [Passes::Peephole]
          #passes = [Passes::Peephole]

          @instructions = @cfg.instructions(*passes)
          @cfg.write_to_dot_file
          puts "(post) # of instr: #{@instructions.length}"
          #puts "INSTRS:\n#{@instructions.map { |i| i.disasm }.join("\n")}"
        else
          @instructions = image
        end

        @jump_table = calculate_jump_table(@instructions) # {label -> index}
        reset
      end

      def disasm
        puts "SAAA"
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