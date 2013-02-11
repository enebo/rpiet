require 'rpiet/direction_pointer'

module RPiet
  class CodelChooser
    LEFT, RIGHT = -1, 1
    attr_reader :direction
    def initialize; @direction = LEFT; end
    def switch!(amount = 1); @direction *= -1.**(amount % 2); end

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

    def inspect
      (@direction == LEFT ? "left(0)" : "right(1)")
    end
    alias :to_s :inspect
  end
end

