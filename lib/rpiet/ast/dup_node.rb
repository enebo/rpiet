require_relative 'node'

module RPiet
  ##
  # Duplicate top element of the stack.
  class DupNode < Node
    def execute(machine)
      stack = machine.stack
      stack << stack[-1] if stack[-1]
    end
  end
end