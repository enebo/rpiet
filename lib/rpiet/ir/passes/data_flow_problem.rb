module RPiet
  module IR
    module Passes
      class DataFlowProblem
        attr_reader :computed, :worklist, :cfg
        attr_accessor :debug

        def initialize(cfg, flow_node_class)
          @cfg, @flow_node_class, @debug = cfg, flow_node_class, false
        end

        def run
          # we will walk forward but want to pop to remove entries so it will appear backwards!
          @worklist = @cfg.postorder_bbs.map {|bb| @flow_node_class.new(self, bb) }
          @node_map = {}
          @computed = @worklist.each_with_object({}) do |node, h|
            h[node] = true
            @node_map[node.bb] = node
          end

          while !@worklist.empty?
            @worklist.pop.compute_data_flow_info
          end
        end

        def node_for(bb)
          @node_map[bb]
        end
      end
    end
  end
end
