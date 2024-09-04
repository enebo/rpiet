require_relative 'node'
require_relative 'math_node'

module RPiet
  ##
  # Modulos two values from stack
  class ModNode < MathNode
    def initialize(group, step, x, y)
      super(group, step, x, y, :%)
    end
  end
end