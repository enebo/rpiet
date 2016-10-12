require_relative 'node'

module RPiet
  ##
  # Display top element of the stack to the console as a character.
  class CoutNode < Node
    def execute(machine)
      print machine.stack.pop.chr
    end
  end
end