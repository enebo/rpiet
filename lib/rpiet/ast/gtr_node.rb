require_relative 'node'

module RPiet
  ##
  # Greater than operation on top two stack values
  class GtrNode < Node
    def execute(machine)
      stack = machine.stack
      return nil unless stack.length >= 2
      a, b = stack.pop(2)
      stack << (a > b ? 1 : 0)
    end
  end
end