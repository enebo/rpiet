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
    def deltas = [1, 0]
  end

  class << Direction::DOWN
    include DirectionExtras
    def deltas = [0, 1]
  end

  class << Direction::LEFT
    include DirectionExtras
    def deltas = [-1, 0]
  end

  class << Direction::UP
    include DirectionExtras
    def deltas = [0, -1]
  end

  class DirectionPointer
    attr_accessor :direction

    def initialize(value=nil)
      @direction = value ? RPiet::Direction::RIGHT.abs(value) : RPiet::Direction::RIGHT
    end

    def ==(other)
      @direction == other.direction
    end

    def rotate!(amount = 1)
      @direction = @direction.incr amount
      self
    end

    def degrees = @direction.value * 90

    def from_ordinal!(ordinal)
      @direction = @direction.abs(ordinal)
      self
    end

    def as_constant = %w[RIGHT DOWN LEFT UP][ordinal]

    def next_possible(x, y) = @direction.next_point(x, y)

    def ordinal = @direction.value

    ASCII_ARROWS = ['>', 'v', '<', '^']
    def ascii = ASCII_ARROWS[@direction.value]

    def inspect = ordinal.to_s
    alias :to_s :inspect
  end
end
