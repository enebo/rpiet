require_relative 'instructions'
require 'rgl/adjacency'
require 'rgl/dot'
require 'rgl/edge_properties_map'

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
      attr_reader :entry_bb

      def initialize(instrs)
        @graph, @bb_map, @edge_labels = RGL::DirectedAdjacencyGraph.new, {}, {}
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
        @bb_map[label] = bb = BasicBlock.new(label)
        @graph.add_vertex(bb)
        @graph.set_vertex_options(bb, shape: 'box', style: 'rounded')
        bb
      end

      def add_forward_edge(source_bb, target_label, forward_refs)
        target_bb = @bb_map[target_label]

        if target_bb
          add_jump_edge(source_bb, target_bb)
        else
          forward_refs[target_label] ||= []
          forward_refs[target_label] << source_bb
        end
      end

      def add_edge(source_bb, target_bb, edge_type)
        @edge_labels[[source_bb, target_bb]] = edge_type
        @graph.add_edge(source_bb, target_bb)
        @graph.set_edge_options(source_bb, target_bb, label: edge_type.to_s, color: edge_type_color(edge_type))
        target_bb
      end

      def edge_type_color(edge_type) = edge_type == :jump ? 'blue' : 'green'

      def add_jump_edge(source_bb, target_bb) = add_edge(source_bb, target_bb, :jump)
      def add_fallthrough_edge(source_bb, target_bb) = add_edge(source_bb, target_bb, :fall_through)

      def build(instrs)
        forward_references = {}

        current_bb = new_bb("entry")
        @entry_bb = current_bb

        just_jumped = false

        instrs.each do |instr|
          case instr
          when Instructions::TwoOperandJumpInstr    # :gt, :bne, :beq
            just_jumped = false
            current_bb.add_instr(instr)
            add_forward_edge(current_bb, instr.value, forward_references)
            current_bb = add_fallthrough_edge(current_bb, new_bb("fall_thru_#{instr.object_id}"))
          when Instructions::JumpInstr              # :jump
            current_bb.add_instr(instr)
            add_forward_edge(current_bb, instr.value, forward_references)
            just_jumped = true
          when Instructions::LabelInstr
            label = instr.value
            bb = new_bb(label)
            if just_jumped                          # jump foo\nlabel something_else\n
              just_jumped = false
            else
              add_fallthrough_edge(current_bb, bb)
            end
            current_bb = bb
            forward_references[label].each do |source_bb|
              add_jump_edge(source_bb, bb)
            end
          else
            just_jumped = false
            current_bb.add_instr(instr)
          end
        end

        has_edge = @graph.edges.find { |edge| edge.source == current_bb }
        add_fallthrough_edge(current_bb, new_bb("exit")) unless has_edge

        @edge_props = RGL::EdgePropertiesMap.new(@edge_labels, true)
        @graph.write_to_graphic_file
      end

      def outgoing_edges(bb, edge_type=nil)
        @graph.edges.select do |edge|
          edge.source == bb && (!edge_type || @edge_props.edge_property(edge.source, edge.target) == edge_type)
        end
      end

      def linearize
        outgoing_edges(@entry_bb)
      end
    end
  end
end