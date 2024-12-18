require_relative 'instructions'
require 'rgl/adjacency'
require 'rgl/dot'
require 'rgl/edge_properties_map'
require 'rgl/traversal'

module RPiet
  module IR
    # Basic Block is a collection of instructions.  It will commonly be referred to as bb
    # in code and in comments.  bbs is multiple basic blacks.
    class BasicBlock
      attr_reader :label, :instrs
      attr_accessor :debug

      def initialize(label)
        @label, @instrs = label, []
      end

      def add_instr(instr) = @instrs << instr

      def last_instr
        instrs&.last
      end

      # If this bb only meaningfully contains a jump (e.g. jump + noops/label)
      def only_contains_jump?
        instrs&.last.class == Instructions::JumpInstr && !instrs[0...-2].find { |instr| !instr.noop? }
      end

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
      def instructions(*passes)
        passes.each do |pass|
          pass.new(self).run
        end

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

      def outgoing_target(bb, edge_type)
        outgoing_edges(bb, edge_type).map { |edge| edge.target }&.first
      end

      def outgoing_targets(bb)
        outgoing_edges(bb).map { |edge| edge.target }
      end

      def incoming_sources(bb)
        @graph.edges.select { |edge| edge.target == bb }.map {|edge| edge.source}
      end

      def new_bb(label)
        @bb_map[label] = bb = BasicBlock.new(label)
        @graph.add_vertex(bb)
        @graph.set_vertex_options(bb, shape: 'box', style: 'rounded')
        bb
      end

      def remove_bb(bb)
        @bb_map.delete(bb.label)
        @graph.remove_vertex(bb)
        incoming_sources(bb).each { |other| remove_edge(other, bb) }
        outgoing_targets(bb).each { |other| remove_edge(bb, other) }
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

      def remove_edge(source_bb, target_bb)
        @edge_labels.delete([source_bb, target_bb])
        @graph.remove_edge(source_bb, target_bb)
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

      def cull
        #show_single_jump_bbs
        cull_dead_bbs
        cull_isolated_bbs
        remove_empty_bbs
        jump_reduction
        cull_dead_bbs
        cull_isolated_bbs
        recombine_pntr
      end

      def show_single_jump_bbs
        @bb_map.each_value do |bb|
          puts "BB: #{bb.label}"
          puts "---------------"
          puts bb.instrs.map { |i| i.disasm }.join("\n")
          puts
        end
      end

      # doing up to 3 branches + 1 jump can be optimized by recombining these back
      # into a pntr instruction which can just use a jump table
      def recombine_pntr
        pntrs = {}
        @bb_map.each_value do |bb|
          last_instr = bb.last_instr
          #puts "BB #{bb.label} #{last_instr} #{bb.instrs.size}"
          if bb.label.to_s =~ /pntr_3_(\d+)/
            pntrs[$1] ||= []
            pntrs[$1] << [$1, "3", bb]
            next
          end
          if last_instr.kind_of?(Instructions::BEQInstr)
            if last_instr.label.to_s =~ /pntr_(\d+)_(\d+)/
              #puts "1: #{$1}, 2: #{$2}"
              pntrs[$2] ||= []
              pntrs[$2] << [$2, $1, bb]
            end
          end
        end

        pntrs.each_value.sort { |(step, i, _), (step2, i2, _)| step <=> step2 &&  i <=> i2 }

        pntrs.each_value do |list|
          new_instr = Instructions::PntrInstr.new(list[0][0])
          zero_bb = nil
          list.each.each_with_index do |(step, _, bb), i|
            if i != 3
              label = bb.instrs.last.label
              if i == 0
                compare = bb.instrs.last.operand1
                new_instr.operands << compare
                bb.instrs[-1] = new_instr
                zero_bb = bb
              else
                add_edge(zero_bb, outgoing_target(bb, :jump), :jump)
                remove_bb(bb)
              end
              new_instr.operands << label
            else
              if bb.only_contains_jump?
                jump_bb = outgoing_target(bb, :jump)
                remove_bb(bb)
                bb = jump_bb
              end
              add_edge(zero_bb, bb, :jump)
              new_instr.operands << bb.label
            end
          end
        end
      end

      def jump_reduction
        @bb_map.each_value do |bb|
          #puts "BB: #{bb.label}"
          if @graph.out_degree(bb) == 1
            next_bb = outgoing_target(bb, :fall_through)

            if next_bb && @graph.out_degree(next_bb) == 1 && next_bb.only_contains_jump?
              #puts "JUMP REPLACE: #{bb.label} -> #{next_bb.label}"
              jump = next_bb.instrs.last
              if bb.instrs[-1].kind_of?(Instructions::JumpInstr)
                bb.instrs[-1] = jump
              else
                bb.instrs << jump
              end
              remove_edge(bb, next_bb)
              add_edge(bb, outgoing_target(next_bb, :jump), :jump)
              next
            end

            next_bb = outgoing_target(bb, :jump)
            if next_bb && @graph.out_degree(next_bb) == 1 && next_bb.only_contains_jump?
              #puts "JUMP REPLACE: #{bb.label} -> #{next_bb.label}"
              jump = next_bb.instrs.last
              bb.instrs[-1] = jump
              remove_edge(bb, next_bb)
              add_edge(bb, outgoing_target(next_bb, :jump), :jump)
              next
            end
          end
        end
      end

      def remove_empty_bbs
        # This is a bit wonky but pntr[3] needs fall through to jump to body for pntr[3]
        # I do not think the pattern can occur any other way so I am assuming a lot in this
        # method about its structure.  For CFG interp this has no impact but for displaying
        # The CFG itself it removes an empty bb.  It also makes recombining the pntr to
        # a jump table simpler.
        @bb_map.each_value do |bb|
          if @graph.out_degree(bb) == 1 && bb.instrs.empty?
            target = outgoing_target(bb, :fall_through)
            source = incoming_sources(bb).first
            remove_bb(bb)
            add_edge(source, target, :fall_through)
          end
        end
      end

      def cull_dead_bbs
        @bb_map.each_value do |bb|
          jump_bb = outgoing_target(bb, :jump)

          # How we make CFG will only have a fall_through edge if next bb has an incoming edge
          # AND/OR if we have a jump.  We do not act on the incoming edge so we only cull if we
          # see a constant jump
          next unless jump_bb

          fallthrough_bb = outgoing_target(bb, :fall_through)
          last_instr = bb.instrs.last
          if last_instr&.constant?   # We can elminate an edge
            result = last_instr.execute(nil)
            if result
              remove_edge(bb, fallthrough_bb)
            else
              remove_edge(bb, jump_bb)
              puts "DELETING: #{bb.label}:#{last_instr}"
              bb.instrs.delete(last_instr)
            end
          end
        end
      end

      def cull_isolated_bbs
        @bb_map.each do |label, bb|
          next if bb == @entry_bb

          in_degree = incoming_sources(bb).size
          if in_degree == 0 # If we cannot make it to this bb delete itself and its outgoing edged
            remove_bb(bb)
          end
        end
      end

      def combine_bbs(bb)
        other_bb = outgoing_targets(bb)[0]
        puts "combining #{bb.label} with #{other_bb.label}" if debug
        bb.instrs.concat(other_bb.instrs)
        remove_edge(bb, other_bb)
        replace_edge(bb, other_bb, :fall_through)
        replace_edge(bb, other_bb, :jump)
      end

      def replace_edge(bb, other_bb, edge_type)
        other_edge = outgoing_edges(other_bb, edge_type)
        if other_edge
          remove_edge(edge.source, edge.target)
          add_edge(bb, edge.target, edge_type)
        end
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

      def postorder_bbs
        order = []
        @graph.depth_first_visit(@entry_bb) { |v| order << v }
        order
      end

      def postorder_bbs2
        result, work_list, visited = [], [@entry_bb], {@entry_bb => true}

        while !work_list.empty?
          bb = work_list.last
          all_children_visited = true
          outgoing_targets(bb).each do |dest|
            next if visited[dest]
            visited[dest] = true
            all_children_visited = false
            if @graph.out_degree(dest) == 0  # should only be exit bb
              result << dest
            else
              work_list << dest
            end
          end

          if all_children_visited
            work_list.pop
            result << bb
          end
        end

        result
      end

      def preorder_bbs
        postorder_bbs.reverse
      end

      private

      def linearize_inner(sorted_list, visited, bb)
        return if visited[bb]
        visited[bb] = true
        sorted_list << bb

        fall_through = outgoing_target(bb, :fall_through)
        linearize_inner(sorted_list, visited, fall_through) if fall_through
        outgoing_targets(bb).each do |jump|
          next if jump == fall_through
          linearize_inner(sorted_list, visited, jump) if jump
        end
      end

      def outgoing_edges_match?(bb, edge, edge_type)
        edge.source == bb && (!edge_type || @edge_props.edge_property(edge.source, edge.target) == edge_type)
      end

      def check_for_unneeded_jump(current_bb, next_bb, jump)
        if jump.label == next_bb.label
          remove_edge(current_bb, next_bb)
          add_edge(current_bb, next_bb, :fall_through)
          current_bb.instrs.pop
        end
      end

      def check_for_needed_jump(current_bb, next_bb, last_instr)
        return if current_bb == exit_bb
        dest = outgoing_target(current_bb, :fall_through)
        add_jump(current_bb, dest.label, last_instr) if dest && dest != next_bb
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
