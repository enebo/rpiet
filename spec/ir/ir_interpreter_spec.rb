require_relative '../spec_helper'

describe "RPiet::IR::IRInterpreter" do
  it "can exec push" do
    interp = ir_interp(assemble("push 10\n"))
    expect(interp.stack).to eq([])
    interp.next_step
    expect(interp.stack).to eq([10])
  end

  it "can exec pop" do
    interp = ir_interp(assemble("push 10\nv1 = pop\n"))
    interp.next_step
    expect(interp.stack).to eq([10])
    interp.next_step
    expect(interp.stack).to eq([])
  end

  it "can exec add" do
    interp = ir_interp(assemble("v1 = 10 + 2\npush v1\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([12])
  end

  it "can exec add with variable" do
    interp = ir_interp(assemble("v1 = copy 10\nv2 = v1 + 2\npush v2\n"))
    3.times { interp.next_step }
    expect(interp.stack).to eq([12])
  end

  it "can exec sub" do
    interp = ir_interp(assemble("v1 = 10 - 2\npush v1\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([8])
  end

  it "can exec mult" do
    interp = ir_interp(assemble("v1 = 10 * 2\npush v1\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([20])
  end

  it "can exec div" do
    interp = ir_interp(assemble("v1 = 10 / 2\npush v1\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([5])
  end

  it "can exec mod" do
    interp = ir_interp(assemble("v1 = 10 % 2\npush v1\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([0])
  end

  it "can exec pow" do
    interp = ir_interp(assemble("v1 = 10 ** 2\npush v1\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([100])
  end

  it "can exec jump" do
    interp = ir_interp(assemble("jump label\npush 1\nlabel label\npush 0\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([0])
  end

  it "can exec bne" do
    interp = ir_interp(assemble("1 != 2 label\npush 1\nlabel label\npush 2\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([2])
  end

  it "can exec beq" do
    interp = ir_interp(assemble("1 == 1 label\npush 1\nlabel label\npush 2\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([2])
  end

  it "can exec gt" do
    interp = ir_interp(assemble("v1 = 2 > 1\npush v1\n"))
    2.times { interp.next_step }
    expect(interp.stack).to eq([1])
  end

  it "can exec roll" do
    interp = ir_interp(assemble("push 1\npush 2\npush 3\npush 4\npush 3\npush 1\nv1 = pop\nv2 = pop\nroll v2 v1\n"))
    9.times { interp.next_step }
    expect(interp.stack).to eq([1, 4, 2, 3]) # <- [1,2,3,4]  roll 3, 1

    interp = ir_interp(assemble("push 1\npush 2\npush 3\npush 4\npush 3\npush 2\nv1 = pop\nv2 = pop\nroll v2 v1\n"))
    9.times { interp.next_step }
    expect(interp.stack).to eq([1, 3, 4, 2])  # <- [1,2,3,4] roll 3, 2
  end
end