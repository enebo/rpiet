require 'rpiet/direction_pointer'
require 'rpiet/codel_chooser'

module RPiet
  class Group
    include RPiet::Direction
    attr_reader :rgb, :points

    def initialize(rgb, point)
      @rgb, @points = rgb, []
      @max = { RIGHT => [], LEFT => [], UP => [], DOWN => [] }

      self << point
    end

    def point_for(pvm)
      case pvm.dp.direction
      when RIGHT then
        pvm.cc.direction == RPiet::CodelChooser::LEFT ? @rl : @rr
      when LEFT then
        pvm.cc.direction == RPiet::CodelChooser::LEFT ? @ll : @lr
      when DOWN then
        pvm.cc.direction == RPiet::CodelChooser::LEFT ? @dl : @dr
      when UP then
        pvm.cc.direction == RPiet::CodelChooser::LEFT ? @ul : @ur
      end
    end

    def <<(point)
      update_up point
      update_down point
      update_left point
      update_right point
      
      @points << point
    end

    def include?(point)
      @points.include? point
    end

    def finish
      @rl, @rr = ends(@max[RIGHT].sort { |a, b| a[1] <=> b[1] })
      @lr, @ll = ends(@max[LEFT].sort { |a, b| a[1] <=> b[1] })
      @ul, @ur = ends(@max[UP].sort { |a, b| a[0] <=> b[0] })
      @dr, @dl = ends(@max[DOWN].sort { |a, b| a[0] <=> b[0] })
    end

    def ends(list)
      [list[0], list[-1]]
    end
    private :ends

    def update_up(point)
      arr = @max[UP]
      if arr.empty? || point[1] < arr[0][1]
        @max[UP] = [point]
      elsif point[1] == arr[0][1]
        arr << point 
      end
    end

    def update_down(point)
      arr = @max[DOWN]
      if arr.empty? || point[1] > arr[0][1]
        @max[DOWN] = [point]
      elsif point[1] == arr[0][1]
        arr << point         
      end
    end

    def update_left(point)
      arr = @max[LEFT]
      if arr.empty? || point[0] < arr[0][0]
        @max[LEFT] = [point]
      elsif point[0] == arr[0][0]
        arr << point         
      end
    end

    def update_right(point)
      arr = @max[RIGHT]
      if arr.empty? || point[0] > arr[0][0]
        @max[RIGHT] = [point]
      elsif point[0] == arr[0][0]
        arr << point         
      end
    end

    def merge(groups, group)
      group.points.each do |point|
        self << point
        groups[point[0]][point[1]] = self
      end
    end

    def size
      @points.size
    end

    def inspect
      "Group #{rgb}: Size: #{size} Points: #{@points.inspect}\n" +
      "rr #@rr rl #@rl lr #@lr ll #@ll ur #@ur ul #@ul dr #@dr dl #@dl"
    end
    alias :to_s :inspect
  end
end
