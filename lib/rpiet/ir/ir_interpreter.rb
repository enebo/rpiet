require_relative '../asg/parser'
require_relative 'builder'

module RPiet
  module IR
    class IRInterpreter
      attr_reader :stack
      attr_accessor :dp, :cc

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
        @ipc, @stack, @dp, @cc = 0, [], nil, nil
      end

      def calculate_jump_table(instructions)
        jump_table = {}
        instructions.each_with_index do |instr, i|
          # We go one past label since it is merely a marker
          jump_table[instr.operand] = i + 1 if instr.operation == :label
        end
        jump_table
      end

      def next_step
        instr = @instructions[@ipc]

        #puts "NODE: #{instr.graph_node} INSTR: #{instr} #{@stack}"

        @event_handler.instruction(self, instr)
        value = instr.execute(self)
        if instr.jump? && value
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