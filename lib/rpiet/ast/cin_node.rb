require_relative 'node'

module RPiet
  ##
  # Read in character from the console and push on the stack
  class CinNode < Node
    def execute(machine)
      $stdout.write "> "
      machine.stack << $stdin.read(1).ord
    end
  end
end