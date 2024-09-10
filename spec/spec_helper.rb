require_relative '../lib/rpiet/group'
require_relative '../lib/rpiet/image/ascii_image'
require_relative '../lib/rpiet/ir/assembler'

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

  def create_image(string, *r)
    RPiet::Image::AsciiImage.new string, *r
  end

  def assemble(code)
    RPiet::IR::Assembler.assemble(code)
  end
end

RSpec::Matchers.define(:be_label_operand) do |value|
  description { 'is a label operand' }

  match { |actual| actual.type == :label && actual.value == value }
end

RSpec::Matchers.define(:be_numeric_operand) do |value|
  description { 'is a numeric operand' }

  match { |actual| actual.type == :numeric && actual.value == value }
end

RSpec::Matchers.define(:be_variable_operand) do |name|
  description { 'is a variable operand' }

  match { |actual| actual.type == :variable && actual.name == name }
end



RSpec.configure do |c|
  c.include SpecHelper
end