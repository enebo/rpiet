require_relative '../asg'
require_relative 'parser'
require 'pp'

module RPiet
  module ASG
    class GraphInterpreter
      include LiveMachineState

      def initialize(image, event_handler = RPiet::Logger::NoOutput.new)
        @event_handler = event_handler
        # FIXME: need a way to debug parser conditionally from command line
        @graph = Parser.new(image).run
      end

      def reset
        reset_machine()
        @node = @graph
      end

      def next_step
        while @node && @node.hidden?
          @node = @node.exec self
        end
        @node = @node.exec self if @node
      end

      def running?
        @node
      end

      def run
        reset
        while running? do
          next_step
        end
      end
    end
  end
end
