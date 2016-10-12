require_relative 'node'

module RPiet
  ##
  # Greater than operation on top two stack values
  class NotNode < Node
    def execute(machine)
      stack = machine.stack
      top = stack.pop
      stack << (!top || top == 0 ? 1 : 0)
    end
  end
end