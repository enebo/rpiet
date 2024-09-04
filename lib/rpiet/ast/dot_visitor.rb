require 'ruby-graphviz'

require_relative 'visitor'

module RPiet
  class DotVisitor < Visitor
    def initialize
      @graphviz = GraphViz.new(:G, type: :digraph)
      super
    end

    def run(root)
      super(root)
      puts "graph created: graph.png"
      @graphviz.output(png: "graph.png")
    end

    def visit_first(node)
      node1 = @graphviz.add_nodes(node.group.object_id.to_s)
      puts "NODE: #{node}"
      node.paths.each do |other_node|
        puts "OTHER_NODE: #{ other_node}"
        node2 = @graphviz.add_nodes(other_node.group.object_id.to_s)
        edge = @graphviz.each_edge.find do |edge|
          edge.node_one[1..-2] == node1.id.to_s && edge.node_two[1..-2] == node2.id.to_s && edge[:label].to_s[1..-2] == node.operation.to_s
        end
        @graphviz.add_edges(node1, node2, label: node.operation.to_s) unless edge
      end
      super
    end
  end
end