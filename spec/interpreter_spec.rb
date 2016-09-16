require 'rpiet/interpreter'
require 'rpiet/image/ascii_image'

describe "RPiet::Interpreter" do
  let(:push) do
    RPiet::Image::AsciiImage.new <<-EOS
nb db ++
nb ++ ++
++ ++ ++
    EOS
  end

    let(:push_pop) do
      RPiet::Image::AsciiImage.new <<-EOS
nb db nb ++
nb ++ nb ++
++ ++ ++ ++
      EOS
    end

  let(:push_add) do
    RPiet::Image::AsciiImage.new <<-EOS
nb db lb lm ++
nb ++ ++ lm ++
++ ++ ++ ++ ++
    EOS
  end

  it "Can push and terminate" do
    interpreter = RPiet::Interpreter.new push
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq []
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
    expect(interpreter.pvm.stack).to eq [2]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2, 1]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [3]
  end

end
