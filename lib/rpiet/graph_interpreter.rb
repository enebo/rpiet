require_relative 'parser/parser'
require 'pp'

module RPiet
  class GraphInterpreter
    def initialize(image, event_handler=RPiet::Logger::NoOutput.new)
      parser = RPiet::Parser.new(image, event_handler)
      @pvm = RPiet::Machine.new
      @graph = parser.run
    end

    def run
      node = @graph
      while node do
        node = node.exec @pvm
      end
    end
  end
end

