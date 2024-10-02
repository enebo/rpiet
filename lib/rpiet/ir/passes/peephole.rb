module RPiet
  module IR
    module Passes
      class Peephole
        def initialize(cfg)
          @cfg = cfg
          @pushes = {}
          @processed = {}
        end

        def run
          worklist = @cfg.postorder_bbs  # we will walk forward but want to pop to remove entries so it will appear backwards! :(
          computed = {}

          while !worklist.empty?
            bb = worklist.pop
            compute bb, worklist, computed
          end
        end

        def compute(bb, worklist, computed)
          computed[bb] = true

          apply_pre_meet(bb, worklist, computed)
          compute_data_flow(bb, worklist, computed)
        end

        def compute_data_flow(bb, worklist, computed)
          @cfg.incoming_sources.each do |source|
            compute_meet(source, )
          end
        end

            #            3.times do
            #  run_bb(bb)
              #constant_bb(bb)
              #constant_fold_bb(bb)
              #remove_dead_edges(bb)
            #end

            #next_bbs = @cfg.outgoing_edges(bb).map {|edge| edge.target }
            #next_bbs.each { |bb| worklist << bb unless @processed[bb] }
            #  end

          #read_dead_bbs
            #end

        def constant_bb(bb)
          instructions = bb.instrs
          i = 0
          constants = {}
          while i < instructions.length
            instr = instructions[i]

            instr.operands.each_with_index do |operand, i|
              instr.operands[i] = constants[operand] if constants[operand]
            end

            if instr.kind_of?(Instructions::CopyInstr)
              constants[instr.result] = instr.operand
              instructions.delete(instr)
            else
              i += 1
            end
          end
        end

        def constant_fold_bb(bb)
          instructions = bb.instrs
          i = 0
          while i < instructions.length
            instr = instructions[i]
            if instr.kind_of?(Instructions::MathInstr) && instr.constant?
              instructions[i] = Instructions::CopyInstr.new(instr.result, instr.execute(nil))
            end
            i += 1
          end
        end

        def remove_dead_edges(bb)
          last_instr = bb.instrs.last
          if last_instr.kind_of?(Instructions::TwoOperandJumpInstr) && instr.constant? && instr.execute(nil).nil?
            instr.label


          end
        end

        def run_bb(bb)
          @processed[bb] = true
          #puts "RUN for #{bb.label}"
          pushes = []  # lifo instr list
          instructions = bb.instrs
          if instructions.find { |e| e.operation == :roll }
            return
          end

          i = 0
          while i < instructions.length
            instr = instructions[i]
            if instr.kind_of?(Instructions::PushInstr)
              pushes << instr
              i += 1
            elsif instr.kind_of?(Instructions::PopInstr) && !pushes.empty?
              last_push = pushes.pop
              instructions[i] = Instructions::CopyInstr.new(instr.result, last_push.operand)
              instructions.delete(last_push)
            else
              i += 1
            end
          end
        end
      end
    end
  end
end