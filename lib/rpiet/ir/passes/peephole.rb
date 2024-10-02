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
          end
          @cfg.cull
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