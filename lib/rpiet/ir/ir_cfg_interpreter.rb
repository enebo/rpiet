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
        return false unless instr
        value = instr.execute(self)

        if instr.jump? && value
          @ipc = @jump_table[value] || raise("improper jump table #{value}")
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