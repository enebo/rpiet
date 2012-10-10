require 'rpiet/cycle'
require 'rpiet/codel_chooser'

module RPiet
  extend RPiet::CycleMethod
  cycle :Direction, :RIGHT, :DOWN, :LEFT, :UP

  class << Direction::RIGHT; def deltas; [1, 0]; end; end
  class << Direction::DOWN; def deltas; [0, 1]; end; end
  class << Direction::LEFT; def deltas; [-1, 0]; end; end
  class << Direction::UP; def deltas; [0, -1]; end; end

  class DirectionPointer
    attr_reader :direction

    def initialize
      @direction = RPiet::Direction::RIGHT
    end

    def rotate!(amount = 1)
      @direction = @direction.incr amount
    end

    def next_valid(x, y)
      dx, dy = @direction.deltas
      [x + dx, y + dy]
    end

    def inspect
      @direction.inspect
    end
    alias :to_s :inspect
  end
end
