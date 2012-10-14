require 'rpiet/interpreter'
require 'rpiet/image/ascii_image'

describe "RPiet::Interpreter" do
  it "Can push" do
    source = RPiet::Image::AsciiImage.new "nb db ++\nnb ++ ++\n++ ++ ++\n"
    interpreter = RPiet::Interpreter.new(source)

    interpreter.next_step
    interpreter.pvm.stack.should == [2]
    interpreter.next_step
    interpreter.pvm.stack.should == []
  end
end
