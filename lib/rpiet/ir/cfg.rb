require_relative 'instructions'
require 'rgl/adjacency'
require 'rgl/dot'
require 'rgl/edge_properties_map'

module RPiet
  module IR
    # Basic Block is a collection of instructions.  It will commonly be referred to as bb
    # in code and in comments.  bbs is multiple basic blacks.
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

    # CFG - Control Flow Graph
    #
    # A control flow graph is a directed graph which show the all paths in which a
    # program can flow/traverse.  Having this form for your program opens up the
    # ability to perform various compiler optimizations.
    #
    # An if statement, for example, shows a possible flow if the test stmt of the
    # if succeeds.  If it fails then the the flow moves past the if body.  The if
    # body itself flows to that same point:
    #
    #  if test
    #     foo
    #  end
    #  bar
    #
    #    +--------------------+               +----------------+
    #    |   bb: start        |     true      |  bb: if_body   |
    #    +--------------------+------------>>>+----------------+
    #    |   branch_true test |               |  call foo      |
    #    +--------------------+               +----------------+
    #              |                                  |
    #              | false                            |
    #              |                                  |
    #              v                                  |
    #    +--------------------+                       |
    #    |  bb after_if       |                       |
    #    +--------------------+<<<--------------------+
    #    |  call bar          |
    #    +--------------------+
    #
    # This CFG also generates an additional exit BB.  This is the last flow node
    # before execution terminates.  Entry BB is the first node you encounter
    # during execution and where you typically start on any analysis.
    class CFG
      attr_reader :entry_bb, :exit_bb

      def initialize(instrs)
        @graph, @bb_map, @edge_labels = RGL::DirectedAdjacencyGraph.new, {}, {}
        build(instrs)
      end

      def basic_blocks
        @bb_map.values
      end

      # Get a sequential list of instructions from this CFG that can be executed.
      # This will linearize and optimize the CFG before making the instruction
      # list.
      def instructions
        bbs = linearize
        #write_to_dot_file
        bbs.each_with_object([]) { |bb, arr| arr.concat bb.instrs }
      end

      def write_to_dot_file
        @graph.write_to_graphic_file
      end

      def outgoing_edges(bb, edge_type=nil)
        if block_given?
          @graph.edges.each do |edge|
            yield edge if outgoing_edges_match?(bb, edge, edge_type)
          end
        else
          @graph.edges.select { |edge| outgoing_edges_match?(bb, edge, edge_type) }
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

        current_bb = new_bb(:entry)
        @entry_bb = current_bb
        @exit_bb = new_bb(:exit)
        @exit_bb.instrs << Instructions::LabelInstr.new(:exit)

        just_jumped = false

        instrs.each do |instr|
          case instr
          when Instructions::TwoOperandJumpInstr    # :gt, :bne, :beq
            just_jumped = false
            current_bb.add_instr(instr)
            add_forward_edge(current_bb, instr.value, forward_references)
            current_bb = add_fallthrough_edge(current_bb, new_bb("fall_thru_#{instr.object_id}"))
          when Instructions::ExitInstr
            just_jumped = true
            add_jump(current_bb, @exit_bb.label, instr)
            add_jump_edge(current_bb, @exit_bb)
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
            forward_references[label]&.each do |source_bb|
              add_jump_edge(source_bb, bb)
            end
            current_bb.add_instr(instr)
          else
            just_jumped = false
            current_bb.add_instr(instr)
          end
        end

        has_edge = @graph.edges.find { |edge| edge.source == current_bb }
        add_fallthrough_edge(current_bb, @exit_bb) unless has_edge

        @edge_props = RGL::EdgePropertiesMap.new(@edge_labels, true)
      end

      # Linearization rearranges basic blocks around fall throughs all being sequentially after
      # the previous fall through bb. All bbs jumped to will get put after that.
      #
      # For these moved blocks we need to add a jump to the bb where execution continues from
      # that bb unless the next bb happens to be right after it.
      #
      # The opposite case is true where last instr is a jump but the jump location happens to
      # be the next bb.  In that case we remove the jump.
      #
      # Piet only has two edge types (fall_through, jump) which makes this simpler than
      # other languages which may return (from procedures/functions) or may raise exceptions.
      def linearize
        sorted_list, visited = [], {@exit_bb => true}
        linearize_inner(sorted_list, visited, @entry_bb)
        sorted_list << @exit_bb
        recalculate_jumps(sorted_list)
        sorted_list
      end

      private

      def linearize_inner(sorted_list, visited, bb)
        return if visited[bb]
        visited[bb] = true
        sorted_list << bb

        outgoing_edges(bb, :fall_through).each { |edge| linearize_inner(sorted_list, visited, edge.target) }
        outgoing_edges(bb, :jump).each { |edge| linearize_inner(sorted_list, visited, edge.target) }
      end

      def outgoing_edges_match?(bb, edge, edge_type)
        edge.source == bb && (!edge_type || @edge_props.edge_property(edge.source, edge.target) == edge_type)
      end

      def check_for_unneeded_jump(current_bb, next_bb, jump)
        current_bb.instrs.pop if jump.label == next_bb.label
      end

      def check_for_needed_jump(current_bb, next_bb, last_instr)
        return if current_bb == exit_bb
        dest = outgoing_edges(current_bb, :fall_through).first.target
        add_jump(current_bb, dest.label, last_instr) if dest != next_bb
      end

      def add_jump(bb, label, last_instr)
        jump = Instructions::JumpInstr.new(label)
        jump.graph_node = last_instr&.graph_node
        bb.instrs << jump
      end

      def recalculate_jumps(bbs)
        bbs.each_with_index do |bb, index|
          last_instr = bb.instrs.last
          if last_instr&.operation == :jump
            check_for_unneeded_jump(bb, bbs[index + 1], last_instr)
          else
            check_for_needed_jump(bb, bbs[index + 1], last_instr)
          end
        end
      end
    end
  end
end
