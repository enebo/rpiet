require 'rpiet/group'
require 'rpiet/machine'

describe "Group" do
  before do
    @group = RPiet::Group.new('0x0000c0', [0, 3])
    [[0, 4], [0, 5], [0, 6], [0, 7], [1, 3], [1, 4], [1, 5], 
     [1, 6], [2, 3], [2, 4], [2, 5], [2, 6], [3, 3], [3, 4], [3, 5], [3, 6], 
     [4, 3], [4, 4], [4, 5], [4, 6], [5, 4], [6, 4], [6, 5], [6, 6], [7, 4], 
     [7, 5], [7, 6], [8, 5], [8, 6]].each do |point|
      @group << point
    end
    @group.finish

    @group2 = RPiet::Group.new('0xff0000', [7, 0])
    
    [[7, 1], [6, 1], [6, 2], [5, 2], [6, 3], [7, 2], 
     [7, 3], [8, 0], [8, 1]].each do |point|
      @group2 << point
    end
    @group2.finish

    @pvm = RPiet::Machine.new
  end

  it "knows its size" do
    @group.size.should == 30
  end

  it "can pick the right points" do
    @group.point_for(@pvm).should == [8, 5] # dp: RIGHT cc: LEFT  -> UR
    @pvm.cc.switch! # LEFT -> RIGHT
    @group.point_for(@pvm).should == [8, 6] # dp: RIGHT cc: RIGHT  -> LR
    @pvm.dp.rotate! # dp: RIGHT -> DOWN
    @pvm.cc.switch! # cc: RIGHT -> LEFT
    @group.point_for(@pvm).should == [0, 7] # dp: DOWN cc: LEFT -> LR
    @pvm.cc.switch! # cc: LEFT -> RIGHT
    @group.point_for(@pvm).should == [0, 7] # dp: DOWN cc: RIGHT -> LL
    @pvm.dp.rotate! # dp: DOWN -> LEFT
    @pvm.cc.switch! # cc: RIGHT -> LEFT
    @group.point_for(@pvm).should == [0, 7] # dp: LEFT cc: LEFT -> LL
    @pvm.cc.switch! # cc: LEFT -> RIGHT
    @group.point_for(@pvm).should == [0, 3] # dp: LEFT cc: RIGHT -> UL
    @pvm.dp.rotate! # dp: LEFT -> UP
    @pvm.cc.switch! 
    @group.point_for(@pvm).should == [0, 3] # dp: UP cc: LEFT -> UL
    @pvm.cc.switch! # cc: LEFT -> RIGHT
    @group.point_for(@pvm).should == [4, 3] # dp: UP cc: RIGHT -> UR

    # Since last group only has single wide bottom let's try another
    @pvm.cc.switch! # cc: RIGHT -> LEFT
    @pvm.dp.rotate! 2 # dp: UP -> DOWN
    @group2.point_for(@pvm).should == [7, 3] # dp: DOWN cc: LEFT -> LR
    @pvm.cc.switch! # cc: RIGHT -> LEFT
    @group2.point_for(@pvm).should == [6, 3] # dp: DOWN cc: RIGHT -> LL
  end
end
