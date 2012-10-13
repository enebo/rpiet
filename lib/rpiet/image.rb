require 'java'
require 'rpiet/color'

# Raw in Java is BufferendImage.  In MRI it just needs to define:
#  width, height, getRGB(x, y)
module RPiet
  class Image
    def initialize(file, codel_size=1)
      @raw = javax.imageio.ImageIO.read(java.net.URL.new(file))
      @codel_size = codel_size
    end

    def pixel(x, y)
      rgb = @raw.getRGB(x * @codel_size, y * @codel_size)
      r, g, b = (rgb >> 16 ) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff
      # This could be a lot nicer :)
      color_for(format "0x%02x%02x%02x" % [r,g, b])
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
      [@raw.width/@codel_size, @raw.height/@codel_size]
    end
  end
end
