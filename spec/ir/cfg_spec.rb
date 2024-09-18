require_relative '../spec_helper'
require_relative '../../lib/rpiet/asg/parser'
require_relative '../../lib/rpiet/ir/builder'
require_relative '../../lib/rpiet/ir/cfg'


describe "RPiet::Builder" do
  let(:push_divide) {
    assemble("push 10\npush 2\nv1 = pop\nv2 = pop\nv3 = v2 / v1; push v3")
  }

  let(:gtr) {
    assemble <<~EOS
push 10
push 2
v1 = pop
v2 = pop
v2 > v1 true
push 0
jump end
label true
push 1
label end
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
    EOS
  }

  it "can visit all nodes once plus one extra visit for a cycle" do
    cfg = RPiet::IR::CFG.new(pntr)
  end
end