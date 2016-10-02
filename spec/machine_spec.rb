require 'rpiet/machine'

describe "RPiet::Machine" do
  it "can roll" do
    machine = RPiet::Machine.new
    expect(machine.dp.direction).to eq(RPiet::Direction::RIGHT)
    expect(machine.cc.to_s).to eq("l")

    [115, 100, 101, 2, 1].each do |value|
      machine.block_value = value
      machine.push
    end

    machine.roll
    expect(machine.stack).to eq [115, 101, 100]

    [3, 1].each do |value|
      machine.block_value = value
      machine.push
    end

    machine.roll
    expect(machine.stack).to eq [100, 115, 101]
  end
end
