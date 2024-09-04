module RPiet
  module Optimizer
    def optimize
      return next_node.optimize if self.kind_of? NoopNode

      if next_node.kind_of? NoopNode
        self.next_node = next_node.next_node.optimize
      end

      self
    end
  end
end