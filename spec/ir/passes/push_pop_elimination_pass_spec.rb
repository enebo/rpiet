require_relative '../../spec_helper'
require_relative '../../../lib/rpiet/ir/cfg'
require_relative '../../../lib/rpiet/ir/passes/push_pop_elimination_pass'

describe "RPiet::IR::Passes:PushPopElimination" do
  let(:gtr) {
    assemble <<~EOS
      push 10
      push 5
      10 != 2 true
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

  it "can eliminate v2+v3 pops" do
    instructions = gtr
    puts "(initial) # of instr: #{instructions.length}"
    @cfg = RPiet::IR::CFG.new(instructions)
    push_pop_elim = RPiet::IR::Passes::PushPopEliminationProblem.new(@cfg)
    push_pop_elim.debug = true
    push_pop_elim.run
    puts "instructions: #{@cfg.instructions.map { |i| i.disasm }.join("\n")}"
  end
end