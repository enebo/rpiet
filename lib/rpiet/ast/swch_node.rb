require_relative 'node'
require_relative '../codel_chooser'

module RPiet
  ##
  # Rotate the codel chooser based on top stack value and
  # change execution flow.
  class SwchNode < Node
    def branch?
      true
    end

    def add_path(node, cc, _)
      if cc == RPiet::CodelChooser::LEFT
        @left = node
      else
        @right = node
      end
    end

    # What possible paths can this node navigate to next
    def paths
      [@left, @right]
    end

    def execute(machine)
      top = machine.stack.pop
      if machine.cc.switch!(top) == RPiet::CodelChooser::LEFT
        @left
      else
        @right
      end
    end
  end
end