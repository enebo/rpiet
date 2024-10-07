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
              roll_elimination(bb)
            end

            poperand_optimize(bb)
            remove_extra_cc_dp(bb)
          end
          @cfg.cull
        end

        def remove_extra_cc_dp(bb)
          instructions = bb.instrs
          @dps, @ccs = [], []

          instructions.each do |instr|
            case instr
            when Instructions::DPRotateInstr
              @dps = []
            when Instructions::DPInstr
              @dps << instr
            when Instructions::CCToggleInstr
              @ccs = []
            when Instructions::CCInstr
              @ccs << instr
            end
          end

          @ccs[0...-1].each { |instr| instructions.delete(instr) } if @ccs.length > 1
          @dps[0...-1].each { |instr| instructions.delete(instr) } if @dps.length > 1
        end

        def roll_elimination(bb)
          instructions = bb.instrs
          @roll_vars ||= 0
          i = 0
          while i < instructions.length
            instr = instructions[i]
            if instr.kind_of?(Instructions::RollInstr) && instr.constant?
              new_instructions = []
              new_variables = []
              depth = instr.depth
              depth.times do
                variable = Operands::VariableOperand.new("r#{@roll_vars}")
                @roll_vars += 1
                new_variables << variable
                new_instructions << Instructions::PopInstr.new(variable)
              end
              num = instr.num
              num = depth+num if num < 0
              new_variables[0...num].reverse_each do |var|
                new_instructions << Instructions::PushInstr.new(var)
              end
              new_variables[num..-1].reverse_each do |var|
                new_instructions << Instructions::PushInstr.new(var)
              end

              instructions[i, 1] = new_instructions
            end
            i += 1
          end
        end

        def poperand_optimize(bb)
          instructions = bb.instrs
          pops = []
          dead_instrs = []

          uses = instructions.each_with_object({}) do |instr, h|
            instr.operands.each do |operand|
              if operand.kind_of?(Operands::VariableOperand)
                h[operand] ||= 0
                h[operand] += 1
              end
            end
          end

          i = 0
          while i < instructions.length
            instr = instructions[i]

            if instr.kind_of?(Instructions::PopInstr)
              #puts "pushing another pop #{instr}"
              pops << instr
            elsif instr.kind_of?(Instructions::PushInstr)
              pops = []
            elsif contains_variables(instr)
              roll = true if instr.kind_of?(Instructions::RollInstr)
              if !pops.empty?
                #puts "processing #{instr} with these pops #{pops.map {|p| p.disasm }.join(", ")}"
                instr.operands.each_with_index do |operand, i|
                  break if pops.empty?
                  # This is at best conservative but it is wrong
                  #puts "#{pops.last.result} <=> #{operand}"
                  if pops.last.result == operand && uses[operand] == 1
                    #puts "replacing #{operand} with a pop and removing #{pops.last.result}"
                    instr.operands[i] = Operands::Poperand.new
                    dead_instrs << pops.pop
                  end
                end
              end

              pops = [] if roll
              roll = false
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

        def contains_variables(instr)
          instr.operands.filter { |operand| operand.kind_of?(Operands::VariableOperand) }
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
              instr.execute(nil)
              instructions[i] = Instructions::CopyInstr.new(instr.result, instr.result.value)
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