require_relative '../lib/rpiet/direction_pointer'

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

  it "knows it's ordinal values" do
    dp = RPiet::DirectionPointer.new
    expect(dp.ordinal).to eq(0)
    dp.rotate!
    expect(dp.ordinal).to eq(1)
    dp.rotate!
    expect(dp.ordinal).to eq(2)
    dp.rotate!
    expect(dp.ordinal).to eq(3)
    dp.rotate!
    expect(dp.ordinal).to eq(0)
  end

  it "can restore from it's ordinal values" do
    dp = RPiet::DirectionPointer.new
    dp.from_ordinal!(0)
    expect(dp.direction).to eq(RPiet::Direction::RIGHT)
    dp.from_ordinal!(1)
    expect(dp.direction).to eq(RPiet::Direction::DOWN)
    dp.from_ordinal!(2)
    expect(dp.direction).to eq(RPiet::Direction::LEFT)
    dp.from_ordinal!(3)
    expect(dp.direction).to eq(RPiet::Direction::UP)
    dp.from_ordinal!(4)
    expect(dp.direction).to eq(RPiet::Direction::RIGHT)
  end
end
