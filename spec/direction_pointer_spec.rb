require 'rpiet/direction_pointer'

describe "DirectionPointer" do
  it "can rotate" do
    dp = RPiet::DirectionPointer.new

    dp.direction.should == RPiet::Direction::RIGHT
    dp.rotate!
    dp.direction.should == RPiet::Direction::DOWN
    dp.rotate!
    dp.direction.should == RPiet::Direction::LEFT
    dp.rotate!
    dp.direction.should == RPiet::Direction::UP
    dp.rotate!(2)
    dp.direction.should == RPiet::Direction::DOWN
  end
end
