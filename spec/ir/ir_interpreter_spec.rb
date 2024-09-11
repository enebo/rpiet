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
    interp.next_step
    interp.next_step
    expect(interp.stack).to eq([12])
  end
  #  %w[+ - * / % **].each do |oper|


end