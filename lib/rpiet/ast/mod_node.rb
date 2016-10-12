require_relative 'node'
require_relative 'math_node'

module RPiet
  ##
  # Modulos two values from stack
  class ModNode < MathNode
    def initialize(step, x, y)
      super(step, x, y, :%)
    end
  end
end