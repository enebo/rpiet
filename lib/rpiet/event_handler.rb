module RPiet
  module EventHandler
    def dmesg(message)
      $stderr.puts message
    end

    def initialized(runtime)
    end

    def next_possible(runtime, ex, ey, valid)
    end

    def step_begin(runtime, ex, ey)
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
        dmesg "codel_size: #{runtime.source.codel_size}"
        dmesg "size: #{runtime.source.cols}x#{runtime.source.rows}"
      end

      def step_begin(runtime, ex, ey)
        dmesg "step \##{runtime.step} -- #{runtime.pvm}"
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
      def step_begin(runtime, ex, ey)
        super
        dmesg runtime.source.ascii(runtime.groups[runtime.x][runtime.y])
      end
    end

    class Graphical < SimpleAsciiOutput
      def initialized(runtime)
        require 'rpiet/debugger/debugger'
        $rpiet = runtime
        $event_handler = self
        runtime.pause
        Thread.new { RPiet::Debugger.launch }.run
      end

      def debugger_started(debugger)
        @debugger = debugger
      end

      def step_begin(runtime, ex, ey)
        @debugger.highlight(runtime, ex, ey)
        if @debugger.break_point?(ex, ey)
          puts "Break point at #{ex}, #{ey}"
        end
      end
      alias :trying_again :step_begin

      def next_possible(runtime, x, y, valid)
        @debugger.highlight_candidate(runtime, x, y, valid)
      end

      def operation(runtime, operation)
        @debugger.operation(runtime, operation)
      end

      def seen_white(runtime)
        puts "SEEN WHITE"
      end

      def trying_again(runtime, ex, ey)
        puts "Trying again"
      end
    end
  end
end
