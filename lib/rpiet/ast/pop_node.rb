require_relative 'node'

module RPiet
  ##
  # Pop a value from the stack
  class PopNode < Node
    def execute(machine)
      machine.stack.pop
    end
  end
end