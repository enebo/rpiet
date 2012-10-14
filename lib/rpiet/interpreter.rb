require 'rpiet/color'
require 'rpiet/machine'
require 'rpiet/group'
require 'rpiet/event_handler'

module RPiet
  class Interpreter
    attr_reader :pvm, :source, :groups, :x, :y, :step

    def initialize(source, event_handler=RPiet::Logger::NoOutput.new)
      @x, @y, @pvm, @step = 0, 0, RPiet::Machine.new, 1
      @source, @event_handler = source, event_handler
      @rows, @cols = @source.size
      @pixels = alloc_matrix { |i, j| @source.pixel(i, j)}
      @groups = calculate_groups(alloc_matrix { |i, j| 0 })
      @event_handler.initialized(self)
    end

    def run
      while(next_step) do
      end
    end

    ##
    # Is this point on the image and not black?
    def valid?(x, y)
      x >= 0 && x < @rows && y >= 0 && y < @cols && 
        @pixels[x][y] != RPiet::Color::BLACK
    end

    def next_step
      @pvm.block_value = @groups[@x][@y].size
      i = 0
      seen_white = false
      @event_handler.step_begin(self)
      ex, ey = @groups[@x][@y].point_for(@pvm)
      while i < 8 do
        nx, ny = @pvm.next_possible(ex, ey)

        if !valid?(nx, ny)
          i += 1
          @pvm.orient_elsewhere(i)

          ex, ey = @groups[@x][@y].point_for(@pvm) if !seen_white
          @event_handler.trying_again(self, ex, ey)
          next
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

    # always look up, left, or make new group
    def calculate_groups(groups)
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
      groups
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
