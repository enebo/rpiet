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

      def new_bb(label)
        @bb_map[label] = BasicBlock.new(label)
      end

      def add_edge(source_bb, target_label, forward_refs)
        target_bb = @bb_map[target_label]

        if target_bb
          @graph.add_edge(source_bb, target_bb)
        else
          forward_refs[target_label] << source_bb
        end
      end

      def build(instrs)
        forward_references = Hash.new { |h, key| [] }
        fall_through = true    # one side of a branch just flows to next BB

        current_bb = new_bb("entry")

        instrs.each do |instr|
          case instr
          when Instructions::JumpInstr
            current_bb.add_instr(instr)
            add_edge(current_bb, instr.value.value, forward_references)
          when Instructions::LabelInstr
            label = instr.value
            bb = new_bb(label)
            @graph.add_edge(current_bb, bb) if fall_through
            current_bb = bb
            forward_references[label].each do |source_bb|
              @graph.add_edge(source_bb, bb)
            end
          else
            current_bb.add_instr(instr)
          end
        end

        has_edge = @graph.edges.find { |edge| edge.source.label == current_bb.label }
        @graph.add_edge(current_bb, new_bb("exit")) unless has_edge
        @graph.write_to_graphic_file
      end
    end
  end
end