module RPiet
  module IR
    module Passes
      class Peephole
        def initialize(cfg)
          @cfg = cfg
        end

        def run
          @cfg.basic_blocks do |bb|
            run_bb(bb)
          end
        end

        def run_bb(bb)
          instructions = bb.instrs
          loop do
            last_push = nil
            i = 0
            changed = false
            while i < instructions.length
              instr = instructions[i]
              if instr.kind_of?(Instructions::PushInstr)
                last_push = instr
              elsif instr.kind_of?(Instructions::PopInstr) && last_push
                changed = true
                # puts "Replacing instructions[#{i}] = #{instructions[i]}"
                # puts "Removing = #{last_push}"
                instructions[i] = Instructions::CopyInstr.new(instr.result, last_push.operand)
                instructions.delete(last_push)
                last_push = nil
                next
              elsif instr.stack_affecting?
                last_push = nil
              end
              i += 1
            end
            break unless changed
          end
        end
      end
    end
  end
end