require 'jrubyfx'
require 'rpiet/image/image'

# Raw in Java is BufferendImage.  In MRI it just needs to define:
#  width, height, getRGB(x, y)
module RPiet
  module Image
    class URLImage < RPiet::Image::Image
      include JRubyFX::DSL

      def initialize(file, codel_size=1)
        super(codel_size)
        image = image(file)
        @width, @height = image.width, image.height
        @raw = image.pixel_reader
      end

      def raw_pixel(x, y)
        rgb = @raw.get_color(x, y)

        [(rgb.red*255).to_i, (rgb.green*255).to_i, (rgb.blue*255).to_i]
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
