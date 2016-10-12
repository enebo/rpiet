require_relative 'node'

module RPiet
  ##
  # Push a value onto the stack
  class PushNode < Node
    attr_reader :value

    def initialize(step, x, y, value)
      super(step, x, y)
      @value = value
    end

    def execute(machine)
      machine.stack << @value
    end
  end
end