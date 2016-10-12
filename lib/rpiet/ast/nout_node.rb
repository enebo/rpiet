require_relative 'node'

module RPiet
  ##
  # Diplay top element of the stack to the console.
  class NoutNode < Node
    def execute(machine)
      print machine.stack.pop
    end
  end
end