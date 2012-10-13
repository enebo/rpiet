module RPiet
  module EventHandler
    def dmesg(message)
      $stderr.puts message
    end

    def initialized(runtime)
    end

    def step_begin(runtime)
    end

    def trying_again(runtime, ex, ey)
    end

    def seen_white(runtime)
    end

    def execution_completed(runtime)
    end

    def operation(runtime, operation)
    end
  end

  module Logger
    class NoOutput
      include RPiet::EventHandler
    end
    
    class SimpleAsciiOutput
      include RPiet::EventHandler

      def initialized(runtime)
        dmesg "codel_size: #{runtime.codel_size}"
      end

      def step_begin(runtime)
        dmesg "step \##{runtime.step_number} -- #{runtime.pvm}"
      end

      def trying_again(runtime, ex, ey)
        dmesg "Trying again at #{ex}, #{ey}. #{runtime.pvm}"
      end

      def seen_white(runtime)
        dmesg "Entering white; sliding thru"
      end

      def execution_completed(runtime)
        dmesg "Execution trapped, program terminates"
      end

      def operation(runtime, operation)
        dmesg "exec: #{operation} -- #{runtime.pvm}"
      end
    end

    class ComplexAsciiOutput < SimpleAsciiOutput
      def step_begin(runtime)
        super
        dmesg runtime.source.ascii(runtime.groups[runtime.x][runtime.y])
      end
    end
  end
end
