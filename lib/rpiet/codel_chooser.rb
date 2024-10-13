require_relative 'direction_pointer'

module RPiet
  class CodelChooser
    LEFT, RIGHT = -1, 1
    attr_reader :direction

    def initialize; @direction = LEFT; end
    def switch!(amount = 1)
      @direction *= -1.**(amount % 2)
      self
    end

    def ascii(dp)
      case dp.direction
      when RPiet::Direction::RIGHT
        @direction == LEFT ? "^" : "v"
      when RPiet::Direction::UP
        @direction == LEFT ? "<" : ">"
      when RPiet::Direction::LEFT
        @direction == LEFT ? "v" : "^"
      when RPiet::Direction::DOWN
        @direction == LEFT ? ">" : "<"
      end
    end

    def degrees(dp)
      case dp.direction
      when RPiet::Direction::RIGHT
        @direction == LEFT ? 270 : 90
      when RPiet::Direction::UP
        @direction == LEFT ? 180 : 0
      when RPiet::Direction::LEFT
        @direction == LEFT ? 90 : 270
      when RPiet::Direction::DOWN
        @direction == LEFT ? 0 : 180
      end
    end

    alias :ordinal :direction

    def from_ordinal!(ordinal)
      @direction = ordinal == LEFT ? LEFT : RIGHT
    end

    def inspect
      @direction.to_s
      #(@direction == LEFT ? "<-" : "->")
    end
    alias :to_s :inspect
  end
end

