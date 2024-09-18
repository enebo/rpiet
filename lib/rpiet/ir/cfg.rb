require_relative 'instructions'
require 'rgl/adjacency'
require 'rgl/dot'

module RPiet
  module IR
    class BasicBlock
      attr_reader :label, :instrs

      def initialize(label)
        @label, @instrs = label, []
      end

      def add_instr(instr) = @instrs << instr

      # Maybe a bit hacky but inspect is for dot output. consider changing this.
      def inspect
        str = "name: #{@label}\n\n"
        str << "#{@instrs.map {|i| i}.join('\l')}\\l" if !@instrs.empty?
        str
      end
      alias :to_s :inspect
    end

    class CFG
      def initialize(instrs)
        @graph, @bb_map = RGL::DirectedAdjacencyGraph.new, {}
        build(instrs)
      end

      def basic_blocks
        @bb_map.values
      end

      def instructions
        @bb_map.values.each_with_object([]) do |bb, arr|
          arr.concat bb.instrs
        end
      end

      def new_bb(label)
        @bb_map[label] = BasicBlock.new(label)
      end

      def add_forward_edge(source_bb, target_label, forward_refs)
        target_bb = @bb_map[target_label]

        if target_bb
          @graph.add_edge(source_bb, target_bb)
        else
          forward_refs[target_label] ||= []
          forward_refs[target_label] << source_bb
        end
      end

      def build(instrs)
        forward_references = {}

        current_bb = new_bb("entry")

        just_jumped = false

        instrs.each do |instr|
          case instr
          when Instructions::TwoOperandJumpInstr
            just_jumped = false
            current_bb.add_instr(instr)
            add_forward_edge(current_bb, instr.value, forward_references)
            fall_through_bb = new_bb("fall_thru_#{instr.object_id}")
            @graph.add_edge(current_bb, fall_through_bb)
            current_bb = fall_through_bb
          when Instructions::JumpInstr
            current_bb.add_instr(instr)
            add_forward_edge(current_bb, instr.value, forward_references)
            just_jumped = true
          when Instructions::LabelInstr
            label = instr.value
            bb = new_bb(label)
            if just_jumped
              just_jumped = false
            else
              @graph.add_edge(current_bb, bb)
            end
            current_bb = bb
            forward_references[label].each do |source_bb|
              @graph.add_edge(source_bb, bb)
            end
          else
            just_jumped = false
            current_bb.add_instr(instr)
          end
        end

        has_edge = @graph.edges.find { |edge| edge.source == current_bb.label }
        @graph.add_edge(current_bb, new_bb("exit")) unless has_edge
        @graph.write_to_graphic_file
      end
    end
  end
end