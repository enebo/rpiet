require 'rpiet/parser/parser'
require 'rpiet/ir/builder'
require 'rpiet/image/ascii_image'

describe "RPiet::Builder" do
  let(:cycle) do
    RPiet::Image::AsciiImage.new <<-EOS
nb db nb
db ++ nb
db db db
    EOS
  end

  it "can visit all nodes once plus one extra visit for a cycle" do
    graph = RPiet::Parser.new(cycle).run
    builder = RPiet::Builder.new
    graph.visit builder
    p builder.instructions
  end
end