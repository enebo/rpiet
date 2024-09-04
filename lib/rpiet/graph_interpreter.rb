require_relative 'parser/parser'
require 'pp'

module RPiet
  class GraphInterpreter
    attr_reader :pvm

    def initialize(image, event_handler=RPiet::Logger::NoOutput.new)
      @graph = RPiet::Parser.new(image, event_handler).run
    end

    def reset
      @pvm = RPiet::Machine.new
      @node = @graph
    end

    def next_step
      @node = @node.exec @pvm
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

