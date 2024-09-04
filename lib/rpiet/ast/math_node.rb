require_relative 'node'

module RPiet
  ##
  # Perform common mathematical binary operation
  class MathNode < Node
    def initialize(group, step, x, y, operation)
      super(group, step, x, y)
      @operation = operation
    end

    def execute(machine)
      stack = machine.stack
      return nil unless stack.length >= 2
      a, b = stack.pop(2)
      stack << a.send(@operation, b)
    end
  end
end