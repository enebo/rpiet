require 'rpiet/color'
require 'rpiet/machine'
require 'rpiet/source'
require 'rpiet/event_handler'

module RPiet
  class Interpreter
    attr_reader :pvm, :source, :pixels, :x, :y, :step

    def initialize(image, event_handler=RPiet::Logger::NoOutput.new)
      @interpreter_thread = Thread.current
      @x, @y, @pvm, @step = 0, 0, RPiet::Machine.new, 1
      @source, @event_handler = RPiet::Source.new(image), event_handler
      @event_handler.initialized(self)
    end

    def pause
      @paused = true
    end

    def resume
      @paused = false
      @interpreter_thread.run
    end

    def advance
      @paused = true
      @interpreter_thread.run
    end

    def abort
      @abort = true
      resume
    end

    def run
      Thread.stop if @paused
      while(next_step) do
        Thread.stop if @paused
      end
    end

    def next_step
      return false if @abort
      @pvm.block_value = @source.group_at(@x, @y).size
      attempt = 1
      seen_white = false
      ex, ey = @source.group_at(@x, @y).point_for(@pvm)                         # Exit point from group
      @event_handler.step_begin(self, ex, ey)
      while attempt <= 8 do
        nx, ny = @pvm.next_possible(ex, ey)                                     # where we enter Next group
        valid = @source.valid?(nx, ny)
        @event_handler.next_possible(self, ex, ey, nx, ny, valid)
        Thread.stop if @paused

        if !valid
          attempt += 1
          @pvm.orient_elsewhere(attempt)

          ex, ey = @source.group_at(@x, @y).point_for(@pvm) if !seen_white
          @event_handler.trying_again(self, ex, ey)
        elsif @source.pixels[nx][ny] == RPiet::Color::WHITE
          if !seen_white
            seen_white = true
            attempt = 0
            @event_handler.seen_white(self)
          end
          ex, ey = nx, ny
        else
          if !seen_white
            operation = @pvm.execute(@source.pixels[nx][ny], @source.pixels[@x][@y])
          else
            operation = 'noop'            
          end
          @event_handler.operation(self, operation)
          @x, @y = nx, ny
          @step += 1
          return true
        end
      end
      @event_handler.execution_completed(self)
      false
    end
  end
end
