require 'java'
require 'rpiet/image/image'

# Raw in Java is BufferendImage.  In MRI it just needs to define:
#  width, height, getRGB(x, y)
module RPiet
  module Image
    class URLImage < RPiet::Image::Image
      def initialize(file, codel_size=1)
        super(codel_size)
        @raw = javax.imageio.ImageIO.read(java.net.URL.new(file))
      end

      def raw_pixel(x, y)
        rgb = @raw.getRGB(x, y)
        [(rgb >> 16 ) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff]
      end

      def raw_width
        @raw.width
      end

      def raw_height
        @raw.height
      end
    end
  end
end
