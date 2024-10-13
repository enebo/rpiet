
require 'rpiet/image/image'

# Raw in Java is BufferendImage.  In MRI it just needs to define:
#  width, height, getRGB(x, y)
module RPiet
  module Image
    if RUBY_ENGINE == "jruby"
      class URLImage < RPiet::Image::Image
        attr_reader :raw_width, :raw_height

        def initialize(file, codel_size=1)
          super(codel_size)
          image = javax.imageio.ImageIO.read(java.net.URL.new(file))
          @raw_width, @raw_height, @raw = image.width, image.height, image
        end

        def raw_pixel(x, y)
          rgb = java.awt.Color.new(@raw.get_rgb(x, y))

          [rgb.red, rgb.green, rgb.blue]
        end
      end
    else
      require 'mini_magick'
      class URLImage < RPiet::Image::Image
        attr_reader :raw_width, :raw_height

        def initialize(file, codel_size=1)
          super(codel_size)
          file = file[5..-1] if file.start_with?('file:')
          image = MiniMagick::Image.open(file)
          @raw_width, @raw_height, @raw = image.width, image.height, image.get_pixels
        end

        def raw_pixel(x, y)
          @raw[y][x]
        end
      end
    end
  end
end
