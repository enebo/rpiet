require 'rpiet/interpreter'
require 'rpiet/image/ascii_image'

describe "RPiet::Interpreter" do

  let(:push_pop) do # [push 2, pop]*
    RPiet::Image::AsciiImage.new <<-EOS
nb db ++
nb ++ ++
++ ++ ++
    EOS
  end

  let(:push_add) do # [push 2, push 1, add, ...]
    RPiet::Image::AsciiImage.new <<-EOS
nb db lb lm ++
nb ++ ++ lm ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_subtract) do # [push 2, push 1, subtract, ...]
    RPiet::Image::AsciiImage.new <<-EOS
nb db lb nm ++
nb ++ ++ nm ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_multiply) do # [push 2, push 2, multiply, ...]
    RPiet::Image::AsciiImage.new <<-EOS
nb db lb dm ++
nb db ++ dm ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_divide) do # [push 2, push 2, divide, ...]
    RPiet::Image::AsciiImage.new <<-EOS
nb db lb lr ++
nb db ++ lr ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_mod) do # [push 2, push 2, mod, ...]
    RPiet::Image::AsciiImage.new <<-EOS
nb db lb nr ++
nb db ++ nr ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_not) do # [push 2, push 2, mod, not, ...]
    RPiet::Image::AsciiImage.new <<-EOS
nb db lb nr lg ++
nb db ++ nr lg ++
++ ++ ++ ++ ++ ++
    EOS
  end

  let(:skip_white) do
    RPiet::Image::AsciiImage.new <<-EOS
nb .. .. db ++
nb .. .. ++ ++
++ .. .. ++ ++
    EOS
  end

  it "Can push and pop" do
    interpreter = RPiet::Interpreter.new push_pop
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq []
  end

  it "Can push and add" do
    interpreter = RPiet::Interpreter.new push_add
    interpreter.next_step
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2, 1]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [3]
  end

  it "Can push and subtract" do
    interpreter = RPiet::Interpreter.new push_subtract
    interpreter.next_step
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2, 1]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [1]
  end

  it "Can push and multiply" do
    interpreter = RPiet::Interpreter.new push_multiply
    interpreter.next_step
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2, 2]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [4]
  end

  it "Can push and divide" do
    interpreter = RPiet::Interpreter.new push_divide
    interpreter.next_step
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2, 2]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [1]
  end

  it "Can push and mod" do
    interpreter = RPiet::Interpreter.new push_mod
    interpreter.next_step
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2, 2]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [0]
  end

  it "Can push and not" do
    interpreter = RPiet::Interpreter.new push_not
    interpreter.next_step
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2, 2]
    interpreter.next_step
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [1]
  end

  it "Can skip white and push and pop" do
    interpreter = RPiet::Interpreter.new push_pop
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq []
  end

end
