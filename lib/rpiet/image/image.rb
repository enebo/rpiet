require 'rpiet/color'

module RPiet
  module Image
    ##
    # Abstract base class for all image providers.  Image providers only need to
    # implement raw_pixel, raw_width, and raw_height.
    #
    class Image
      attr_reader :codel_size 

      def initialize(codel_size)
        @codel_size = codel_size
      end

      def pixel(x, y)
        r,g,b = raw_pixel(x * @codel_size, y * @codel_size)
        color_for(format "0x%02x%02x%02x" % [r,g,b])
      end

      def color_for(rgb_hex)
        RPiet::Color::RGB[rgb_hex]
      end

      def ascii(group = [])
        s = ''
        w, h = size
        h.times do |j|
          w.times do |i|
            value = pixel(i, j).to_initial 
            s << (group.include?([i, j]) ? value.upcase : value) << ' '
          end
          s << "\n"
        end
        s
      end

      def size
        [raw_width/@codel_size, raw_height/@codel_size]
      end
    end
  end
end
