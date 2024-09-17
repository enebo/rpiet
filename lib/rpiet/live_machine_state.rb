module RPiet
  module LiveMachineState
    attr_reader :stack, :event_handler
    attr_accessor :dp, :cc

    def reset_machine
      @stack, @dp, @cc = [], DirectionPointer.new, CodelChooser.new
    end

    def inspect
      "dp: #{dp}, cc: #{cc}, st: #{stack}"
    end
    alias :to_s :inspect
  end
end