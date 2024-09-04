require_relative '../lib/rpiet/group'

module SpecHelper
  ##
  # Takes a description of a group as an newline-delimited string
  # where all '#' characters represent the group you want to create
  # and any other character is insignificant.  Here is a simple
  # example of a group in the shape of a 'T':
  #
  # my_group_ascii << EOS
  # ...#####...
  # .....#.....
  # .....#.....
  # .....#.....
  # EOS
  #
  def ascii_to_group_points(string)
    points = []
    string.split("\n").each_with_index do |line, j|
      line.split('').each_with_index do |char, i|
        points << [i, j] if char == '#'
      end
    end
    points
  end

  def create_group(color, string)
    RPiet::Group.new(color, *ascii_to_group_points(string)).tap { |g| g.calculate_corners }
  end
end

RSpec.configure do |c|
  c.include SpecHelper
end