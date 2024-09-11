require_relative '../spec_helper'
require_relative '../../lib/rpiet/asg/parser'
require_relative '../../lib/rpiet/ir/builder'

describe "RPiet::Builder" do
  let(:cycle) do
    create_image <<-EOS
nb db nb
db ++ nb
db db db
    EOS
  end

  it "can visit all nodes once plus one extra visit for a cycle" do
    graph = RPiet::ASG::Parser.new(cycle).run
    builder = RPiet::Builder.new
    builder.run graph
    #p builder.instructions
  end
end
