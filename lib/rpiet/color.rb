require_relative 'cycle'

module RPiet
  class Color
    extend RPiet::CycleMethod

    cycle :LIGHTNESS, :LIGHT, :NORMAL, :DARK
    cycle :HUE, :RED, :YELLOW, :GREEN, :CYAN, :BLUE, :MAGENTA

    attr_reader :hue, :lightness, :rgb

    def initialize(lightness, hue, rgb)
      @lightness, @hue, @rgb = lightness, hue, rgb
    end

    def color_from(lightness_delta: 0, hue_delta: 0)
      LIGHTNESS_HUE[lightness.incr(lightness_delta)][hue.incr(hue_delta)]
    end
    
    # Display color as initial of lightness followed by hue (normal blue == nb).
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

    LIGHT_RED = Color.new(LIGHTNESS::LIGHT, HUE::RED, '0xffc0c0')
    LIGHT_YELLOW = Color.new(LIGHTNESS::LIGHT, HUE::YELLOW, '0xffffc0')
    LIGHT_GREEN = Color.new(LIGHTNESS::LIGHT, HUE::GREEN, '0xc0ffc0')
    LIGHT_CYAN = Color.new(LIGHTNESS::LIGHT, HUE::CYAN, '0xc0ffff')
    LIGHT_BLUE = Color.new(LIGHTNESS::LIGHT, HUE::BLUE, '0xc0c0ff')
    LIGHT_MAGENTA = Color.new(LIGHTNESS::LIGHT, HUE::MAGENTA, '0xffc0ff')
    RED = Color.new(LIGHTNESS::NORMAL, HUE::RED, '0xff0000')
    YELLOW = Color.new(LIGHTNESS::NORMAL, HUE::YELLOW, '0xffff00')
    GREEN = Color.new(LIGHTNESS::NORMAL, HUE::GREEN, '0x00ff00')
    CYAN = Color.new(LIGHTNESS::NORMAL, HUE::CYAN, '0x00ffff')
    BLUE = Color.new(LIGHTNESS::NORMAL, HUE::BLUE, '0x0000ff')
    MAGENTA = Color.new(LIGHTNESS::NORMAL, HUE::MAGENTA, '0xff00ff')
    DARK_RED = Color.new(LIGHTNESS::DARK, HUE::RED, '0xc00000')
    DARK_YELLOW = Color.new(LIGHTNESS::DARK, HUE::YELLOW, '0xc0c000')
    DARK_GREEN = Color.new(LIGHTNESS::DARK, HUE::GREEN, '0x00c000')
    DARK_CYAN = Color.new(LIGHTNESS::DARK, HUE::CYAN, '0x00c0c0')
    DARK_BLUE = Color.new(LIGHTNESS::DARK, HUE::BLUE, '0x0000c0')
    DARK_MAGENTA = Color.new(LIGHTNESS::DARK, HUE::MAGENTA, '0xc000c0')

    RGB = {
      '0xffc0c0' => LIGHT_RED, '0xffffc0' => LIGHT_YELLOW, '0xc0ffc0' => LIGHT_GREEN,
      '0xc0ffff' => LIGHT_CYAN, '0xc0c0ff' => LIGHT_BLUE, '0xffc0ff' => LIGHT_MAGENTA,
      '0xff0000' => RED, '0xffff00' => YELLOW, '0x00ff00' => GREEN,
      '0x00ffff' => CYAN, '0x0000ff' => BLUE, '0xff00ff' => MAGENTA,
      '0xc00000' => DARK_RED, '0xc0c000' => DARK_YELLOW, '0x00c000' => DARK_GREEN,
      '0x00c0c0' => DARK_CYAN, '0x0000c0' => DARK_BLUE, '0xc000c0' => DARK_MAGENTA,
      RGB_WHITE => WHITE,
      RGB_BLACK => BLACK
    }

    LIGHTNESS_HUE = {
      LIGHTNESS::LIGHT => {
        HUE::RED => LIGHT_RED,
        HUE::YELLOW => LIGHT_YELLOW,
        HUE::GREEN => LIGHT_GREEN,
        HUE::CYAN => LIGHT_CYAN,
        HUE::BLUE => LIGHT_BLUE,
        HUE::MAGENTA => LIGHT_MAGENTA
      },
      LIGHTNESS::NORMAL => {
        HUE::RED => RED,
        HUE::YELLOW => YELLOW,
        HUE::GREEN => GREEN,
        HUE::CYAN => CYAN,
        HUE::BLUE => BLUE,
        HUE::MAGENTA => MAGENTA
      },
      LIGHTNESS::DARK => {
        HUE::RED => DARK_RED,
        HUE::YELLOW => DARK_YELLOW,
        HUE::GREEN => DARK_GREEN,
        HUE::CYAN => DARK_CYAN,
        HUE::BLUE => DARK_BLUE,
        HUE::MAGENTA => DARK_MAGENTA
      }

    }
  end
end
