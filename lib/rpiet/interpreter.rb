require 'rpiet/color'
require 'rpiet/machine'
require 'rpiet/group'
require 'rpiet/event_handler'

module RPiet
  class Interpreter
    attr_reader :pvm, :source, :pixels, :groups, :x, :y, :step, :rows, :cols

    def initialize(source, event_handler=RPiet::Logger::NoOutput.new)
      @interpreter_thread = Thread.current
      @x, @y, @pvm, @step = 0, 0, RPiet::Machine.new, 1
      @source, @event_handler = source, event_handler
      @rows, @cols = @source.size
      @pixels = alloc_matrix { |i, j| @source.pixel(i, j)}
      @groups_matrix, @groups = calculate_groups
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

    def run
      Thread.stop if @paused
      while(next_step) do
        Thread.stop if @paused
      end
    end

    ##
    # Is this point on the image and not black?
    def valid?(x, y)
      x >= 0 && x < @rows && y >= 0 && y < @cols && 
        @pixels[x][y] != RPiet::Color::BLACK
    end

    def next_step
      @pvm.block_value = @groups_matrix[@x][@y].size
      i = 0
      seen_white = false
      ex, ey = @groups_matrix[@x][@y].point_for(@pvm)
      @event_handler.step_begin(self, ex, ey)
      while i < 8 do
        nx, ny = @pvm.next_possible(ex, ey)
        valid = valid?(nx, ny)
        @event_handler.next_possible(self, nx, ny, valid)
        Thread.stop if @paused

        if !valid
          i += 1
          @pvm.orient_elsewhere(i)

          ex, ey = @groups_matrix[@x][@y].point_for(@pvm) if !seen_white
          @event_handler.trying_again(self, ex, ey)
        elsif @pixels[nx][ny] == RPiet::Color::WHITE
          if !seen_white
            seen_white = true
            i = 0
            @event_handler.seen_white(self)
          end
          ex, ey = nx, ny
        else
          if !seen_white
            operation = @pvm.execute(@pixels[nx][ny], @pixels[@x][@y])
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

    ##
    # With grid of pixels start in upper left corner processing each pixel
    # rightwards and downwards. As you encounter a pixel look up and left to
    # see if it is a new color or part of an existing neighboring group.
    def calculate_groups
      groups = alloc_matrix { |i, j| 0 }
      all_groups = []
      walk_matrix(groups) do |i, j|
        rgb = @pixels[i][j]
        up = j-1 >= 0 ? groups[i][j-1] : nil
        left = i-1 >= 0 ? groups[i-1][j] : nil
        if up && up.rgb == rgb
          up << [i, j]
          groups[i][j] = up
          # disjoint groups to merge
          up.merge(groups, left) if left && left != up && left.rgb == rgb
        end

        if groups[i][j] == 0 && left && left.rgb == rgb
          left << [i, j]
          groups[i][j] = left
        end

        if groups[i][j] == 0
          groups[i][j] = RPiet::Group.new(rgb, [i, j])
          all_groups << groups[i][j]
        end
      end
      all_groups.each { |group| group.finish }
      return groups, all_groups
    end

    def alloc_matrix
      Array.new(@rows) { Array.new(@cols) {nil} }.tap do |matrix|
        walk_matrix(matrix) { |i, j| matrix[i][j] = yield i, j }
      end
    end

    def walk_matrix(matrix)
      0.upto(@rows-1) do |i|
        0.upto(@cols-1) do |j|
          yield i, j
        end
      end
    end
  end
end
