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

  context "outgoing_edges" do
    it "can see all edges in a simple graph" do
      cfg = RPiet::IR::CFG.new(gtr)

      entry_bb = cfg.entry_bb
      result = cfg.outgoing_edges(entry_bb, :fall_through)
      expect(result.size).to eq(1)
      fall_through = result[0].target
      expect(fall_through.label).to start_with("fall_thru_")

      result = cfg.outgoing_edges(entry_bb, :jump)
      expect(result.size).to eq(1)
      jump = result[0].target
      expect(jump.label).to eq(:true)

      result = cfg.outgoing_edges(jump, :fall_through)
      expect(result.size).to eq(1)
      end_bb = result[0].target
      expect(end_bb.label).to eq(:end)

      result = cfg.outgoing_edges(fall_through, :jump)
      expect(result.size).to eq(1)
      end_bb2 = result[0].target
      expect(end_bb.label).to eq(:end)

      expect(end_bb).to eq(end_bb2)
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

    it "can visit all nodes once plus one extra visit for a cycle" do
      cfg = RPiet::IR::CFG.new(pntr)
    end
  end
end