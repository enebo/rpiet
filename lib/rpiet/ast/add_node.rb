require_relative 'node'
require_relative 'math_node'

module RPiet
  ##
  # Add two values from stack
  class AddNode < MathNode
    def initialize(group, step, x, y)
      super(group, step, x, y, :+)
    end
  end
end