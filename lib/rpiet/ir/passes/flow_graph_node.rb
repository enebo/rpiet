module RPiet
  module IR
    module Passes
      class FlowGraphNode
        attr_reader :bb, :problem

        def initialize(problem, bb)
          @problem, @bb = problem, bb
        end

        def cfg = problem.cfg
        def computed = problem.computed
        def debug = problem.debug
        def worklist = problem.worklist

        def compute_data_flow_info
          computed[self] = false

          apply_pre_meet_handler
          compute_flow_info
        end

        def compute_flow_info
          puts "compute_flow_info for #{bb.label}" if debug
          cfg.incoming_sources(bb).each do |source|
            puts "  <--- #{source.label}" if debug
            compute_meet(problem.node_for(source))
          end

          solution do
            bb.instrs.each { |instr| apply_transfer_function(instr) }
            requeue_target_bbs(cfg.outgoing_targets(bb)) if solution_changed?
          end
        end

        def solution
          solution_init
          yield
          assign_outs
        end

        # Something changed and so we need to reprocess these flow nodes.
        def requeue_target_bbs(bbs)
          bbs.filter { |bb| !computed[bb] }.each do |bb|
            computed[bb] = true
            worklist << problem.node_for(bb)
          end
        end

        def apply_pre_meet_handler
        end

        def apply_transfer_function(instr)
        end

        # See define_ins
        def assign_outs
        end

        # Function which merges out values from the incoming flow nodes.
        # Define appropriate logic to apply MOP (to merge results into a
        # new in set for this node).
        def compute_meet(node)
        end

        # Construct the data structure to represent the values of this node
        # in terms to resolve with in and to become out.
        def solution_init
        end

        def solution_changed?
        end
      end
    end
  end
end