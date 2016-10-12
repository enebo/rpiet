require_relative 'node'

module RPiet
  ##
  # Read in number from the console and push on the stack
  class NinNode < Node
    def execute(machine)
      puts "Enter an integer: "
      machine.stack << $stdin.gets.to_i
    end
  end
end