module RPiet
  class CodelChooser
    LEFT, RIGHT = -1, 1
    attr_reader :direction
    def initialize; @direction = LEFT; end
    def switch!(amount = 1); @direction *= -1.**(amount % 2); end

    def inspect
      @direction.inspect
    end
    alias :to_s :inspect
  end
end

