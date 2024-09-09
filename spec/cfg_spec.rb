require_relative 'spec_helper'
require_relative '../lib/rpiet/asg/parser'
require_relative '../lib/rpiet/ir/builder'
require_relative '../lib/rpiet/ir/cfg'
require_relative '../lib/rpiet/ir/constant_propagation'
require_relative '../lib/rpiet/ir/dead_code_elimination'
require_relative '../lib/rpiet/ir/peephole'
require_relative '../lib/rpiet/image/url_image'


describe "RPiet::Builder" do
  let(:cycle) do
    create_image <<-EOS
nb db nb
db ++ nb
db db db
    EOS
  end

  let(:push_divide) do # [push 2, push 2, divide, ...]
    create_image <<-EOS
nb db lb lr ++
nb db ++ lr ++
++ ++ ++ lr ++
++ ++ lr lr ++
++ ++ ++ ++ ++
    EOS
  end

  # it "can visit all nodes once plus one extra visit for a cycle" do
  #   graph = RPiet::ASG::Parser.new(push_divide).run
  #   builder = RPiet::Builder.new
  #   builder.run graph
  #   RPiet::IR::DeadCodeElimination.run(builder.instructions)
  #   cfg = RPiet::IR::CFG.new(builder.instructions)
  # end

  it "can" do
    filename = 'file:images/nfib.png'
    puts "a.1"
    image = RPiet::Image::URLImage.new(filename, 1)
    puts "a.2"
    graph = RPiet::ASG::Parser.new(image).run
    puts "a.3"
    builder = RPiet::Builder.new
    puts "a.4"
    builder.run graph
    puts "a.5"
    RPiet::IR::Peephole.run(builder.instructions)
    RPiet::IR::DeadCodeElimination.run(builder.instructions)
    RPiet::IR::ConstantPropagation.run(builder.instructions)
    cfg = RPiet::IR::CFG.new(builder.instructions)
  end
end