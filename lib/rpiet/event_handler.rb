module RPiet
  module EventHandler
    def dmesg(message)
      $stderr.puts message
    end

    def initialized(runtime)
    end

    def next_possible(runtime, edge_x, edge_y, next_x, next_y, valid)
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

    def instruction(runtime, instruction)
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
        dmesg "step \##{runtime.step} at #{ex} #{ey} -- #{runtime.pvm}"
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

      def instruction(runtime, instruction)
        dmesg "instr: #{instruction}"
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
        unless $event_handler
          require 'rpiet/debugger/debugger'
          $rpiet = runtime
          $event_handler = self
          Thread.new { RPiet::Debugger.launch }.run
        else
          @debugger.begin_session
        end
        runtime.pause
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

      # edge of current group to potential entry point of next group (valid is if next is a valid group).
      def next_possible(runtime, edge_x, edge_y, next_x, next_y, valid)
        @debugger.highlight_candidate(runtime, edge_x, edge_y, next_x, next_y, valid)
      end

      def operation(runtime, operation)
        @debugger.operation(runtime, operation)
      end

      def seen_white(runtime)
        puts "SEEN WHITE"
      end

      def trying_again(runtime, ex, ey)
        @debugger.highlight(runtime, ex, ey)
      end
    end
  end
end
