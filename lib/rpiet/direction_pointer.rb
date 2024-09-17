require_relative 'cycle'
require_relative 'codel_chooser'

module RPiet
  extend RPiet::CycleMethod
  cycle :Direction, :RIGHT, :DOWN, :LEFT, :UP

  module DirectionExtras
    def next_point(x, y)
      dx, dy = deltas
      [x + dx, y + dy]
    end
  end

  class << Direction::RIGHT
    include DirectionExtras
    def deltas; [1, 0]; end
  end

  class << Direction::DOWN
    include DirectionExtras
    def deltas; [0, 1]; end
  end

  class << Direction::LEFT
    include DirectionExtras
    def deltas; [-1, 0]; end
  end

  class << Direction::UP
    include DirectionExtras
    def deltas; [0, -1]; end
  end

  class DirectionPointer
    attr_accessor :direction

    def initialize
      @direction = RPiet::Direction::RIGHT
    end

    def rotate!(amount = 1)
      @direction = @direction.incr amount
    end

    def degrees
      @direction.value * 90
    end

    def from_ordinal!(ordinal)
      @direction = @direction.abs(ordinal)
    end

    def next_possible(x, y)
      @direction.next_point(x, y)
    end

    def ordinal
      @direction.value
    end

    ASCII_ARROWS = ['>', 'v', '<', '^']
    def ascii
      ASCII_ARROWS[@direction.value]
    end

    def inspect
      ordinal.to_s
    end
    alias :to_s :inspect
  end
end
