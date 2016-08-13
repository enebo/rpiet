require 'rpiet/image/image'

module RPiet
  module Image
    class AsciiImage < RPiet::Image::Image
      def initialize(string, codel_size=1)
        super codel_size
        lines = string.split("\n")
        @data = []
        lines.each do |line|
          @data << line.split(/\s+/).map { |e| str_to_rgb(e) }
        end
      end

      def raw_pixel(x, y)
        @data[x][y]
      end

      def raw_height
        @data.length
      end

      def raw_width
        @data[0].length
      end

      STR2RGB = {
        'lr' => [0xff, 0xc0, 0xc0],
        'ly' => [0xff, 0xff, 0xc0],
        'lg' => [0xc0, 0xff, 0xc0],
        'lc' => [0xc0, 0xff, 0xff],
        'lb' => [0xc0, 0xc0, 0xff],
        'lm' => [0xff, 0xc0, 0xff],
        'nr' => [0xff, 0x00, 0x00],
        'ny' => [0xff, 0xff, 0x00],
        'ng' => [0xc0, 0xff, 0x00],
        'nc' => [0x00, 0xff, 0xff],
        'nb' => [0x00, 0x00, 0xff],
        'nm' => [0xff, 0x00, 0xff],
        'dr' => [0xc0, 0x00, 0x00],
        'dy' => [0xc0, 0xc0, 0x00],
        'dg' => [0x00, 0xc0, 0x00],
        'dc' => [0x00, 0xc0, 0xc0],
        'db' => [0x00, 0x00, 0xc0],
        'dm' => [0xc0, 0x00, 0xc0],
        '..' => [0xff, 0xff, 0xff],
        '++' => [0x00, 0x00, 0x00]
      }

      def str_to_rgb(str)
        STR2RGB[str]
      end
    end
  end
end
