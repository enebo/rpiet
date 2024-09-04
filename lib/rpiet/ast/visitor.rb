require 'set'

module RPiet
  # Generic visitor for visiting all nodes in the graph once but
  # then also visiting all nodes which complete a cycle a second time.
  class Visitor
    def initialize
      @visited = Set.new
    end

    def run(root)
      worklist = [root]
      
      visit worklist
    end

    def visit(worklist)
      while !worklist.empty?
        node = worklist.pop
        next unless node
        already_visited = @visited.include? node

        if already_visited
          visit_again node
        else
          @visited.add node
          if node  # child of nil means exit
            if node.operation == :pntr
              work_items = visit_first_pntr node, worklist
            elsif node.operation == :swch
              work_items = visit_first_swch node, worklist
            else
              work_items = visit_first node
            end
            worklist.concat work_items if work_items && !work_items.empty?
          end
        end
        break if worklist.empty?
      end
    end    

    def visit_children(node)
      node.paths.each do |next_node|
        next_node.visit self if next_node
      end
    end

    def visit_first(node)
      node.paths
    end

    # First time we encounter an individual swch node
    def visit_first_swch(node, worklist=nil)
      node.paths
    end

    # First time we encounter an individual pntr node
    def visit_first_pntr(node, worklist=nil)
      node.paths
    end

    # Second time we encounter any ndoe
    def visit_again(node)
    end
  end
end
