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
          @cfg.linearize.each do |bb|
            3.times do
              push_pop_elimination(bb)
              constant_bb(bb)
              constant_fold_bb(bb)
            end

            two_pop_optimize(bb)
          end
          @cfg.cull
        end

        #dfkslsd;lambda
        # -- this can be generalized to fill in any operand with a pop.  It could be generalized to a poperand
        # or tiny bit more efficient as custom types.  poperand has advantage it would only take a new operand
        # type.
        # -- roll decomposition - can I take 4, -1 and then rewrite it as push/pops?
        # -- assembler needs to be written to accept negative numbers
        def two_pop_optimize(bb)
          instructions = bb.instrs
          pops = []
          dead_instrs = []

          i = 0
          while i < instructions.length
            instr = instructions[i]

            if instr.kind_of?(Instructions::PopInstr)
              pops << instr
            elsif instr.kind_of?(Instructions::PushInstr)
              pops = []
            elsif instr.respond_to?(:two_pop)
              roll = true if instr.kind_of?(Instructions::RollInstr)
              if pops.length >= 2
                dead_instrs.concat(pops.pop(2))
                instructions[i] = instr.two_pop
              end
              pops = [] if roll
              roll = false
            end
            i += 1
          end

          dead_instrs.each do |instr|
            instructions.delete(instr)
          end
        end

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
            if (instr.kind_of?(Instructions::MathInstr) || instr.kind_of?(Instructions::GTInstr)) && instr.constant?
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

        def push_pop_elimination(bb)
          @processed[bb] = true
          #puts "RUN for #{bb.label}"
          pushes = []  # lifo instr list
          instructions = bb.instrs

          i = 0
          while i < instructions.length
            instr = instructions[i]
            if instr.kind_of?(Instructions::PushInstr)
              pushes << instr
            elsif instr.kind_of?(Instructions::NoopInstr) && !instr.kind_of?(Instructions::LabelInstr)
              instructions.delete(instr)
              next
            elsif instr.kind_of?(Instructions::RollInstr)
              # Without knowing roll values we have no way to reason about roll so we just throw out all pushes
              pushes = []
            elsif instr.kind_of?(Instructions::PopInstr) && !pushes.empty?
              last_push = pushes.pop
              #              count = count_map[last_push.operand]
              #if !count || count == 1
                instructions[i] = Instructions::CopyInstr.new(instr.result, last_push.operand)
                instructions.delete(last_push)
              #end
              next
            end
            i += 1
          end
        end
      end
    end
  end
end