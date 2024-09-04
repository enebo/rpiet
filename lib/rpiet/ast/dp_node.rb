require_relative 'node'

module RPiet
  ##
  # When dp changes due to natural navigation we update it
  # to the new value
  class DpNode < Node
    attr_reader :value

    def initialize(group, step, x, y, cc_ordinal, dp_ordinal)
      super(group, step, x, y)
      @value = dp_ordinal
    end

    def execute(machine)
      machine.dp.from_ordinal!(@value)
    end
  end
end