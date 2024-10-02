module RPiet
  module LiveMachineState
    attr_reader :stack, :event_handler
    attr_accessor :dp, :cc, :input, :output

    def reset_machine
      @stack, @dp, @cc, @input, @output = [], DirectionPointer.new, CodelChooser.new, $stdin, $stdout
    end

    def inspect
      "dp: #{dp}, cc: #{cc}, st: #{stack}"
    end
    alias :to_s :inspect
  end
end