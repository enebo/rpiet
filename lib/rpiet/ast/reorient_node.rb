require_relative 'node'

module RPiet
  ##
  # When cc or dp change due to natural navigation
  # through the image we need something to track
  # that.
  class ReorientNode < Node
    def initialize(step, x, y, cc_value, dp_value)
      super(step, x, y)
      @dp_value, @cc_ordinal = dp_value, cc_value
    end

    def execute(machine)
      machine.cc.direction = @cc_value
      machine.dp.direction = machine.dp.direction.abs(@dp_value)
    end
  end
end