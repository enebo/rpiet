require_relative 'color'
require_relative 'group'
require_relative 'image/image'


module RPiet
  class Source
    attr_reader :rows, :cols, :groups, :pixels, :codel_size

    def initialize(image)
      @cols, @rows = image.size
      @codel_size = image.codel_size
      @pixels = alloc_matrix { |i, j| image.pixel(i, j)}
      @groups_matrix, @groups = calculate_groups
    end

    def entry_group
    end

    ##
    # Is this point on the image and not black?
    def valid?(x, y)
      x >= 0 && x < @cols && y >= 0 && y < @rows &&
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
      groups_matrix = alloc_matrix { |i, j| 0 }
      group = []
      walk_matrix do |i, j|
        color = @pixels[i][j]
        up = j-1 >= 0 ? groups_matrix[i][j-1] : nil
        left = i-1 >= 0 ? groups_matrix[i-1][j] : nil
        if up && up.color == color
          up << [i, j]
          groups_matrix[i][j] = up
          # disjoint groups to merge
          if left && left != up && left.color == color
            up.merge(groups_matrix, left)
            left.points.each do |x, y|
              groups_matrix[x][y] = up
              group.delete left
            end
          end
        end

        if groups_matrix[i][j] == 0 && left && left.color == color
          left << [i, j]
          groups_matrix[i][j] = left
        end

        if groups_matrix[i][j] == 0  # Create new group for first codel found
          groups_matrix[i][j] = RPiet::Group.new(color, [i, j])
          group << groups_matrix[i][j]
        end
      end
      group.each { |group| group.calculate_corners }
      return groups_matrix, group
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