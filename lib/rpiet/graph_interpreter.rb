require_relative 'parser/parser'
require 'pp'

module RPiet
  class GraphInterpreter
    def initialize(image, event_handler=RPiet::Logger::NoOutput.new, print)
      @graph = RPiet::Parser.new(image, event_handler).run
      @graph.dot if print == :graph || print == :all
      @pvm = RPiet::Machine.new
    end

    def run
      node = @graph
      while node do
        node = node.exec @pvm
      end
    end
  end
end

