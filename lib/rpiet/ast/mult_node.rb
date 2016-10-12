require_relative 'node'
require_relative 'math_node'

module RPiet
  ##
  # Multiply two values from stack
  class MultNode < MathNode
    def initialize(step, x, y)
      super(step, x, y, :*)
    end
  end
end