require 'set'
require_relative 'node'

module RPiet
  # Generic visitor for visiting all nodes in the graph once but
  # then also visiting all nodes which complete a cycle a second time.
  class Visitor
    def initialize
      @visited = Set.new
    end

    def visit_children(node)
      node.paths.each do |next_node|
        next_node.visit self
      end
    end

    def visit(node)
      already_visited = @visited.include? node
      if !already_visited
        @visited.add node
        visit_first node
        visit_children node
      else
        visit_again node
      end
    end

    def visit_first(node)
    end

    def visit_again(node)
    end
  end
end