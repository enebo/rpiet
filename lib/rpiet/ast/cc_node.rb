require_relative 'node'

module RPiet
  ##
  # When dp changes due to natural navigation we update it
  # to the new value
  class CcNode < Node
    attr_reader :value

    def initialize(step, x, y, cc_ordinal, *)
      super(step, x, y)
      @value = cc_ordinal
    end

    def hidden? = true

    def execute(machine) = machine.cc.from_ordinal!(@value)
  end
end