require_relative 'node'
require_relative 'math_node'

module RPiet
  ##
  # Multiply two values from stack
  class MultNode < MathNode
    def initialize(group, step, x, y)
      super(group, step, x, y, :*)
    end
  end
end