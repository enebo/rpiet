require 'rpiet/parser/parser'
require 'rpiet/ast/visitor'
require 'rpiet/image/ascii_image'

describe "RPiet::Visitor" do
  let(:cycle) do
    RPiet::Image::AsciiImage.new <<-EOS
nb db nb
db ++ nb
db db db
    EOS
  end

  let(:my_visitor) do
    Class.new(RPiet::Visitor) {
      attr_reader :nodes

      def initialize
        super
        @nodes = {}
      end

      def visit_first(node)
        @nodes[node] = 1
      end

      def visit_again(node)
        @nodes[node] += 1
      end
    }.new
  end

  it "can visit all nodes once plus one extra visit for a cycle" do
    graph = RPiet::Parser.new(cycle).run
    graph.visit my_visitor
    expect(my_visitor.nodes.size).to eq(11)
    expect(my_visitor.nodes.values.inject(0) { |s, e| s += e; s}).to eq(12) # 1 node visited twice
  end
end