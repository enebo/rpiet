require 'rpiet/direction_pointer'

describe "DirectionPointer" do
  it "can rotate" do
    dp = RPiet::DirectionPointer.new

    expect(dp.direction).to eq(RPiet::Direction::RIGHT)
    dp.rotate!
    expect(dp.direction).to eq(RPiet::Direction::DOWN)
    dp.rotate!
    expect(dp.direction).to eq(RPiet::Direction::LEFT)
    dp.rotate!
    expect(dp.direction).to eq(RPiet::Direction::UP)
    dp.rotate!(2)
    expect(dp.direction).to eq(RPiet::Direction::DOWN)
  end
end
