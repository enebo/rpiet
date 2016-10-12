require_relative 'node'

module RPiet
  ##
  # Rotate the direction based on top stack value and
  # change execution flow.
  class PntrNode < Node
    def branch?
      true
    end

    def add_path(node, _, dp_value)
      @values ||= []
      @values[dp_value] = node
    end

    def execute(machine)
      top = machine.stack.pop
      @values[machine.dp.rotate!(top).value]
    end
  end
end

