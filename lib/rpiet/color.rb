require 'rpiet/cycle'

module RPiet
  class Color
    extend RPiet::CycleMethod

    cycle :LIGHTNESS, :LIGHT, :NORMAL, :DARK
    cycle :HUE, :RED, :YELLOW, :GREEN, :CYAN, :BLUE, :MAGENTA

    attr_reader :hue, :lightness, :rgb

    def initialize(lightness, hue, rgb)
      @lightness, @hue, @rgb = lightness, hue, rgb
    end

    def to_initial
      @lightness.to_initial + @hue.to_initial
    end

    def to_s
      [@lightness == LIGHTNESS::NORMAL ? nil : @lightness.to_s,
       @hue.to_s].compact.join('_')
    end
    alias :inspect :to_s

    def self.color_for(rgb_hex)
      RGB[rgb_hex]
    end

    RGB_WHITE, WHITE = '0xffffff', Color.new(LIGHTNESS::NORMAL, 'white', '0xffffff')
    RGB_BLACK, BLACK = '0x000000', Color.new(LIGHTNESS::NORMAL, 'black', '0x000000')

    class << WHITE; def to_initial; '..'; end; end
    class << BLACK; def to_initial; '++'; end; end

    RGB = {
      '0xffc0c0' => Color.new(LIGHTNESS::LIGHT, HUE::RED, '0xffc0c0'),
      '0xffffc0' => Color.new(LIGHTNESS::LIGHT, HUE::YELLOW, '0xffffc0'),
      '0xc0ffc0' => Color.new(LIGHTNESS::LIGHT, HUE::GREEN, '0xc0ffc0'),
      '0xc0ffff' => Color.new(LIGHTNESS::LIGHT, HUE::CYAN, '0xc0ffff'),
      '0xc0c0ff' => Color.new(LIGHTNESS::LIGHT, HUE::BLUE, '0xc0c0ff'),
      '0xffc0ff' => Color.new(LIGHTNESS::LIGHT, HUE::MAGENTA, '0xffc0ff'),
      '0xff0000' => Color.new(LIGHTNESS::NORMAL, HUE::RED, '0xff0000'),
      '0xffff00' => Color.new(LIGHTNESS::NORMAL, HUE::YELLOW, '0xffff00'),
      '0x00ff00' => Color.new(LIGHTNESS::NORMAL, HUE::GREEN, '0x00ff00'),
      '0x00ffff' => Color.new(LIGHTNESS::NORMAL, HUE::CYAN, '0x00ffff'),
      '0x0000ff' => Color.new(LIGHTNESS::NORMAL, HUE::BLUE, '0x0000ff'),
      '0xff00ff' => Color.new(LIGHTNESS::NORMAL, HUE::MAGENTA, '0xff00ff'),
      '0xc00000' => Color.new(LIGHTNESS::DARK, HUE::RED, '0xc00000'),
      '0xc0c000' => Color.new(LIGHTNESS::DARK, HUE::YELLOW, '0xc0c000'),
      '0x00c000' => Color.new(LIGHTNESS::DARK, HUE::GREEN, '0x00c000'),
      '0x00c0c0' => Color.new(LIGHTNESS::DARK, HUE::CYAN, '0x00c0c0'),
      '0x0000c0' => Color.new(LIGHTNESS::DARK, HUE::BLUE, '0x0000c0'),
      '0xc000c0' => Color.new(LIGHTNESS::DARK, HUE::MAGENTA, '0xc000c0'),
      RGB_WHITE => WHITE,
      RGB_BLACK => BLACK
    }
  end
end
