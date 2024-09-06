require_relative 'spec_helper'
require_relative '../lib/rpiet/asg/parser'
require_relative '../lib/rpiet/ir/builder'
require_relative '../lib/rpiet/ir/cfg'

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

  it "can visit all nodes once plus one extra visit for a cycle" do
    graph = RPiet::ASG::Parser.new(cycle).run
    builder = RPiet::Builder.new
    builder.run graph
    cfg = RPiet::IR::CFG.new
    cfg.build(builder.instructions)
  end
end