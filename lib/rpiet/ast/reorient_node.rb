require_relative 'node'

module RPiet
  ##
  # When cc or dp change due to natural navigation
  # through the image we need something to track
  # that.
  class ReorientNode < Node
    def initialize(step, x, y, cc_ordinal, dp_ordinal)
      super(step, x, y)
      @dp_value, @cc_ordinal = dp_ordinal, cc_ordinal
    end

    def execute(machine)
      machine.cc.from_ordinal!(@cc_value)
      machine.dp.from_ordinal!(@dp_value)
    end
  end
end