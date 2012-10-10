require 'java'

# Raw in Java is BufferendImage.  In MRI it just needs to define:
#  width, height, getRGB(x, y)
module RPiet
  class Image
    def initialize(file)
      @raw = javax.imageio.ImageIO.read(java.net.URL.new(file))
    end

    def pixel(x, y)
      rgb = @raw.getRGB(x, y)
      r, g, b = (rgb >> 16 ) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff
      format "0x%02x%02x%02x" % [r,g, b]
    end

    def size
      [@raw.width, @raw.height]
    end
  end
end
