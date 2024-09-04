require_relative 'node'

module RPiet
  ##
  # Push a value onto the stack
  class PushNode < Node
    attr_reader :value

    def initialize(group, step, x, y, value)
      super(group, step, x, y)
      @value = value
    end

    def execute(machine)
      machine.stack << @value
    end
  end
end