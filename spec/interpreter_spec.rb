require 'rpiet/interpreter'
require 'rpiet/image/ascii_image'

describe "RPiet::Interpreter" do
  let(:source) do
    RPiet::Image::AsciiImage.new <<-EOS
nb db ++
nb ++ ++
++ ++ ++
    EOS
  end
  it "Can push" do
    interpreter = RPiet::Interpreter.new source

    interpreter.next_step
    expect(interpreter.pvm.stack).to eq [2]
    interpreter.next_step
    expect(interpreter.pvm.stack).to eq []
  end
end
