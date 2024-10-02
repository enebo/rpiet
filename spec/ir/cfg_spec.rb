require_relative '../spec_helper'
require_relative '../../lib/rpiet/asg/parser'
require_relative '../../lib/rpiet/ir/builder'
require_relative '../../lib/rpiet/ir/cfg'


describe "RPiet::IR::CFG" do
  let(:push_divide) {
    assemble("push 10\npush 2\nv1 = pop\nv2 = pop\nv3 = v2 / v1; push v3")
  }

  let(:gtr) {
    assemble <<~EOS
      10 > 2 true
      push 0
      jump end
      label true
      push 1
      label end
      exit
    EOS
  }

  let(:pntr) {
    assemble <<~EOS
      dpset 0
      push 2
      v25 = pop
      v26 = dpget
      v27 = v26 + v25
      v28 = v27 % 4
      dpset v28
      v28 != 0 pntr[0]43
      push 0
      jump re.4008
      label pntr[0]43
      v28 != 1 pntr[1]43
      push 1
      jump re.4008
      label pntr[1]43
      v28 != 2 pntr[2]43
      push 2
      jump re.4008
      label pntr[2]43
      v28 != 3 re.4008
      push 3
      label re.4008
      v29 = pop
      exit
    EOS
  }

  let(:diamond) {
    assemble <<~EOS
      push 10
      push 5
      10 > 2 true
      push 0
      jump end
      label true
      push 1
      label end
      v1 = pop
      v2 = pop
      v3 = pop
      v4 = v3 / v2
      push v4
      exit
    EOS
  }

  let(:graph1) {
    assemble <<~EOS
      push 10
      push 5
      10 > 2 true
      label foo
      push 0
      jump end
      label true
      push 1
      label end
      v1 = pop
      v2 = pop
      v3 = pop
      v4 = v3 / v2
      push v4
      1 != 2 foo
      push 1
      exit
    EOS
  }

  context "outgoing_edges" do
    it "can see all edges in a simple graph" do
      cfg = RPiet::IR::CFG.new(gtr)

      entry_bb = cfg.entry_bb
      fall_through = cfg.outgoing_target(entry_bb, :fall_through)
      expect(fall_through.label).to start_with("fall_thru_")

      jump = cfg.outgoing_target(entry_bb, :jump)
      expect(jump.label).to eq(:true)

      end_bb = cfg.outgoing_target(jump, :fall_through)
      expect(end_bb.label).to eq(:end)

      end_bb2 = cfg.outgoing_target(fall_through, :jump)
      expect(end_bb.label).to eq(:end)

      expect(end_bb).to eq(end_bb2)
    end

    it "can remove an edge" do
      cfg = RPiet::IR::CFG.new(gtr)

      entry_bb = cfg.entry_bb
      jump = cfg.outgoing_target(entry_bb, :jump)
      expect(cfg.outgoing_targets(entry_bb).size).to eq(2)
      cfg.remove_edge(entry_bb, jump)
      expect(cfg.outgoing_targets(entry_bb).size).to eq(1)
    end

    it "can see see outgoing edges with a block" do
      cfg = RPiet::IR::CFG.new(gtr)

      entry_bb = cfg.entry_bb
      results = []
      cfg.outgoing_edges(entry_bb) do |edge|
        results << edge.target.label.to_s
      end
      results.sort!
      expect(results[0]).to start_with("fall_thru_")
      expect(results[1]).to eq("true")
    end

    it "can generate postorder traversal" do
      cfg = RPiet::IR::CFG.new(diamond)
      puts cfg.postorder_bbs.map { |bb| bb.label }.join(", ")
      puts cfg.preorder_bbs.map { |bb| bb.label }.join(", ")
    end

    it "can generate postorder traversal" do
      cfg = RPiet::IR::CFG.new(graph1)
      cfg.write_to_dot_file
      puts cfg.postorder_bbs.map { |bb| bb.label }.join(", ")
      puts cfg.preorder_bbs.map { |bb| bb.label }.join(", ")
    end

  end
end