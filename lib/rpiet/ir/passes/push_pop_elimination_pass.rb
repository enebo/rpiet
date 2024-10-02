require_relative 'data_flow_problem'
require_relative 'flow_graph_node'

module RPiet
  module IR
    module Passes
      class PushInfo
        attr_reader :bb, :instr
        def initialize(bb, instr)
          @bb, @instr = bb, instr
        end

        def ==(other)
          other && operand == other.operand
        end

        def operand = instr&.operand

        def to_s
          "#{bb.label}:#{instr}"
        end
        alias inspect to_s
      end

      class PushPopEliminationNode < FlowGraphNode
        attr_reader :ins, :outs
        TOP, BOTTOM = nil, PushInfo.new(nil, nil)

        def initialize(problem, bb)
          super
        end

        def replace_instr(instr, new_instr)
          index = bb.instrs.index(instr)
          bb.instrs[index] = new_instr
        end

        def apply_transfer_function(instr)
          if instr.operation == :push
            @ins ||= []
            @ins << PushInfo.new(bb, instr)
          elsif instr.operation == :pop
            push = @ins.pop # Can ASG create invalid instrs combos of push/pop?
            if push != TOP && push != BOTTOM
              puts "replace pop #{instr} with #{push.instr} in #{push.bb.label}" if debug
              replace_instr(instr, Instructions::CopyInstr.new(instr.result, push.operand))
              @remove_instrs << [push.bb, push.instr]
            end
          end
        end

        def assign_outs
          puts "assign_outs: #{bb.label}" if debug
          puts "ins: #{@ins}" if debug
          @remove_instrs.each { |bb, instr| bb.instrs.delete(instr) }
          @outs = @ins.dup
          puts "outs: #{@outs}" if debug
        end

        def compute_meet(other)
          if @ins.nil?
            puts "initial meet: #{self} +++ #{other.outs.dup}" if debug
            @ins = other.outs.dup
            return
          end

          puts "continued meet: #{self} +++ #{other}" if debug
          oins = other.outs

          # if one branch has more pushes recorded than another branch then obviously
          # all branches do not have a push to eliminate.  We truncate to shortest of n
          # last pushes.
          if @ins.size > oins.size
            @ins = @ins[-oins.size..-1]
          elsif @ins.size < oins.size
            oins = oins[-@ins.size..-1]
          end

          @ins.zip(oins).each_with_index do |(joined_in, other_in), index|
            if joined_in != other_in
              if other_in != TOP          # Any mismatched value lowers to unsolved
                @ins[index] = BOTTOM
              elsif joined_in == TOP      # if meet has nothing yet then we can give it incoming value
                @ins[index] = other_in    # Note: I doubt this is possible for this pass
              end
            end
          end
        end

        def solution_changed?
          !@remove_instrs.empty?
        end

        def solution_init
          @remove_instrs = []
        end

        def to_s
          "#{bb.label}\n#{bb.instrs.map {|i| i.disasm}.join("\n")}\nins: #{@ins}\nouts: #{@outs}"
        end
        alias inspect to_s

      end

      class PushPopEliminationProblem < DataFlowProblem
        def initialize(cfg)
          super(cfg, PushPopEliminationNode)
        end
      end
    end
  end
end
