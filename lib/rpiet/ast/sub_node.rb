require_relative 'node'
require_relative 'math_node'

module RPiet
  ##
  # Subtract two values from stack
  class SubNode < MathNode
    def initialize(group, step, x, y)
      super(group, step, x, y, :-)
    end
  end
end