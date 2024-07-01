
require 'rpiet/image/image'

# Raw in Java is BufferendImage.  In MRI it just needs to define:
#  width, height, getRGB(x, y)
module RPiet
  module Image
    class URLImage < RPiet::Image::Image
      def initialize(file, codel_size=1)
        super(codel_size)
        image = javax.imageio.ImageIO.read(java.net.URL.new(file))
        @width, @height, @raw = image.width, image.height, image
      end

      def raw_pixel(x, y)
        rgb = java.awt.Color.new(@raw.get_rgb(x, y))

        [rgb.red, rgb.green, rgb.blue]
      end

      def raw_width
        @width
      end

      def raw_height
        @height
      end
    end
  end
end
