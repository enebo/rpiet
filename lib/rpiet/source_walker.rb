require_relative 'codel_chooser'
require_relative 'direction_pointer'
require_relative 'source'


module RPiet
  class SourceWalker
    class State
      attr_reader :x, :y, :cc_direction, :dp_direction, :flow_instr

      def initialize(x, y, cc_direction, dp_direction, flow_instr=nil)
        @x, @y, @cc_direction, @dp_direction, @flow_instr = x, y, cc_direction, dp_direction, flow_instr
      end

      def ==(other)
        #puts "X: #{other.x == @x}"
        #puts "Y: #{other.y == @y}"
        #puts "CCD: #{other.cc_direction== @cc_direction}"
        #puts "DPD: #{other.dp_direction== @dp_direction}"
        value = other.x == @x && other.y == @y && other.cc_direction == @cc_direction && other.dp_direction == @dp_direction
        #p value
        value
      end
#      alias :eql? :==
#      alias :equall? :==

      def inspect
        "#{x}x#{y}: #{cc_direction}=#{dp_direction}"
      end
      alias :to_s :inspect
    end
    attr_reader :cc, :dp
    def initialize(source)
      @source = source
      @x, @y = 0, 0
      @cc = RPiet::CodelChooser.new
      @dp = RPiet::DirectionPointer.new
      @work_list = []
      @already_visited = []
      @cfg = []
    end

    ##
    # Add new state to visit if we haven't already.
    def add_state(state)
      if @already_visited.include?(state) || @work_list.include?(state)
        return nil
      else
        puts "NEVER SEENT YET #{state}"
      end

      puts "NEW STATE #{state}"
      @work_list << state
    end

    def restore_state(state)
      @x, @y = state.x, state.y
      @cc.direction = state.cc_direction
      @dp.direction = state.dp_direction
      @already_visited << state
      @basic_block = []
      @cfg << @basic_block
      require 'pp'
      pp @cfg
      state.flow_instr << @cfg.length if state.flow_instr
    end

    def run
      @work_list << State.new(@x, @y, @cc.direction, @dp.direction)
      while !@work_list.empty?
        puts "removing worklist"
        restore_state(@work_list.pop)
                while(next_step) do
          puts "stepping"
        end
      end
    end

    def next_step
      group = @source.group_at(@x, @y)
      i = 0
      seen_white = false
      ex, ey = group.point_for(self)
      while i < 8 do
        nx, ny = @dp.next_possible(ex, ey)
        valid = @source.valid?(nx, ny)

        if !valid
          i += 1

          if i.even?
            dp.rotate!
          else
            cc.switch!
          end

          ex, ey = group.point_for(self) if !seen_white
        elsif @source.pixels[nx][ny] == RPiet::Color::WHITE
          if !seen_white
            seen_white = true
            i = 0
          end
          ex, ey = nx, ny
        else
          if !seen_white
            operation = calculate_operation @source.pixels[nx][ny], @source.pixels[@x][@y]
          else
            operation = :noop
          end

          # Notes:
          # need index of BBs for jumps to know where to go (index as label)
          # implicit push/pop for impl

          case operation
            when :swch
              swch_instr = [operation]
              @basic_block << swch_instr
              add_state State.new(@x, @y, @cc.switch(0), @dp.direction, swch_instr)
              add_state State.new(@x, @y, @cc.switch(1), @dp.direction, swch_instr)
              return false
            when :pntr
              pntr_instr = [operation]
              @basic_block << pntr_instr
              add_state State.new @x, @y, @cc.direction, @dp.rotate(0), pntr_instr
              add_state State.new @x, @y, @cc.direction, @dp.rotate(1), pntr_instr
              add_state State.new @x, @y, @cc.direction, @dp.rotate(2), pntr_instr
              add_state State.new @x, @y, @cc.direction, @dp.rotate(3), pntr_instr
              return false
            when :push
              @basic_block << [operation, group.size]
            else
              @basic_block << [operation]
          end

          @x, @y = nx, ny
          return true
        end
      end
      false
    end

    ##
    # Execute the operation represented by the two colors
    def calculate_operation(color1, color2)
      dh = color1.hue.delta color2.hue
      dd = color1.lightness.delta color2.lightness
      OPERATION[dh][dd]
    end

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
  end
end