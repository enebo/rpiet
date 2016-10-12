require_relative 'node'
require_relative 'math_node'

module RPiet
  ##
  # Subtract two values from stack
  class SubNode < MathNode
    def initialize(step, x, y)
      super(step, x, y, :-)
    end
  end
end