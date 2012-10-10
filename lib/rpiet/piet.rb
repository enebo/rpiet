require 'rpiet/color'
require 'rpiet/machine'
require 'rpiet/image'
require 'rpiet/group'

module RPiet
  Debug = false
  ##
  #                     Lightness change
  #Hue change     None         1 Darker     2 Darker
  #  None                      push         pop
  # 1 Step        add          subtract     multiply
  # 2 Steps       divide       mod          not
  # 3 Steps       greater      pointer      switch
  # 4 Steps       duplicate    roll         in(number)
  # 5 Steps       in(char)     out(number)  out(char)
  #
  OPERATION = [[:noop, :push, :pop],
               [:add,  :sub, :mult],
               [:div,  :mod, :not],
               [:gtr,  :pntr, :swch],
               [:dup,  :roll, :n_in],
               [:c_in, :nout, :cout]]

  class Interpreter
    def initialize(source, pvm=RPiet::Machine.new)
      @x, @y, @pvm, @debug, @step_number = 0, 0, pvm, RPiet::Debug, 1
      @source = source
      @rows, @cols = @source.size
      @change_flag = false
      @pixels = alloc_matrix { |i, j| @source.pixel(i, j) }
      @groups = calculate_groups(alloc_matrix { |i, j| 0 })
    end

    def valid?(x, y)
      x >= 0 && x < @rows && y >= 0 && y < @cols && 
        @pixels[x][y] != RPiet::Color::RGB_BLACK
    end

    def dmesg(message)
      $stderr.puts message if @debug
    end

    def step
      dmesg "\n-- STEP: #{@step_number}"
      @pvm.block_value = @groups[@x][@y].size
      i = 1
      seen_white = false
      dmesg "Group for #{@x}, #{@y} is #{@groups[@x][@y]}"
      ex, ey = @groups[@x][@y].point_for(@pvm.dp, @pvm.cc)
#      dmesg "E: #{ex}, #{ey}"
      while i <= 8 do
        nx, ny = @pvm.dp.next_valid(ex, ey)
#        dmesg "NEXT: #{nx}, #{ny}"
        if !valid?(nx, ny)
          i += 1
          if @change_flag
            @change_flag = false
            @pvm.dp.rotate!
          else
            @change_flag = true
            @pvm.cc.switch!
          end
          dmesg "Trying again at #{nx}, #{ny}. #{@pvm}"
          ex, ey = @groups[@x][@y].point_for(@pvm.dp, @pvm.cc)
#          dmesg "#{ex}, #{ey}"
          next
        elsif @pixels[nx][ny] == RPiet::Color::RGB_WHITE
          if !seen_white
            seen_white = true
            i = 0
            dmesg "Entering white; sliding thru"
          end
          ex, ey = nx, ny
        else
          dmesg "#{color_s(@x, @y)} @ (#{@x}, #{@y}) -> #{color_s(nx, ny)} @ (#{nx}, #{ny}) DP:#{@pvm.dp} CC:#{@pvm.cc}"
          if !seen_white
            dh = RPiet::Color::RGB[@pixels[nx][ny]].hue.delta(RPiet::Color::RGB[@pixels[@x][@y]].hue)
            dd = RPiet::Color::RGB[@pixels[nx][ny]].lightness.delta(RPiet::Color::RGB[@pixels[@x][@y]].lightness)
            @pvm.__send__(OPERATION[dh][dd])
            dmesg "OPER: #{OPERATION[dh][dd]} dh: #{dh} dd: #{dd}"
          end
          dmesg "Machine state: #{@pvm}"
          @x, @y = nx, ny
          @step_number += 1
          return true
        end
      end
      self.dmesg "Execution trapped, program terminates"
      false
    end

    def color_s(x, y)
      RPiet::Color::RGB[@pixels[x][y]] || @pixels[x][y]
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
