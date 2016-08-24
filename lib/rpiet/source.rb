require_relative 'color'
require_relative 'group'
require_relative 'image/image'


module RPiet
  class Source
    attr_reader :rows, :cols, :groups, :pixels

    def initialize(image)
      @cols, @rows = image.size
      @pixels = alloc_matrix { |i, j| image.pixel(i, j)}
      @groups_matrix, @groups = calculate_groups
    end

    def entry_group
    end

    ##
    # Is this point on the image and not black?
    def valid?(x, y)
      x >= 0 && x < @rows && y >= 0 && y < @cols &&
          @pixels[x][y] != RPiet::Color::BLACK
    end

    def group_at(x, y)
      @groups_matrix[x][y]
    end

    ##
    # With grid of pixels start in upper left corner processing each pixel
    # rightwards and downwards. As you encounter a pixel look up and left to
    # see if it is a new color or part of an existing neighboring group.
    def calculate_groups
      groups = alloc_matrix { |i, j| 0 }
      all_groups = []
      walk_matrix do |i, j|
        rgb = @pixels[i][j]
        up = j-1 >= 0 ? groups[i][j-1] : nil
        left = i-1 >= 0 ? groups[i-1][j] : nil
        if up && up.rgb == rgb
          up << [i, j]
          groups[i][j] = up
          # disjoint groups to merge
          if left && left != up && left.rgb == rgb
            up.merge(groups, left)
            left.points.each do |x, y|
              groups[x][y] = up
              all_groups.delete left
            end
          end
        end

        if groups[i][j] == 0 && left && left.rgb == rgb
          left << [i, j]
          groups[i][j] = left
        end

        if groups[i][j] == 0
          groups[i][j] = RPiet::Group.new(rgb, [i, j])
          all_groups << groups[i][j]
        end
      end
      all_groups.each { |group| group.finish }
      return groups, all_groups
    end

    private def alloc_matrix
      Array.new(@cols) { Array.new(@rows) {nil} }.tap do |matrix|
        walk_matrix {|i, j| matrix[i][j] = yield i, j }
      end
    end

    private def walk_matrix
      0.upto(@cols-1) do |i|
        0.upto(@rows-1) do |j|
          yield i, j
        end
      end
    end
  end
end