require 'rpiet/machine'

describe "RPiet::Machine" do
  it "can roll" do
    machine = RPiet::Machine.new

    [115, 100, 101, 2, 1].each do |value|
      machine.block_value = value
      machine.push
    end

    machine.roll
    machine.stack.should == [115, 101, 100]

    [3, 1].each do |value|
      machine.block_value = value
      machine.push
    end

    machine.roll
    machine.stack.should == [100, 115, 101]
  end
end
