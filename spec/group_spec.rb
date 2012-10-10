require 'rpiet/group'

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

    @dp = RPiet::DirectionPointer.new
    @cc = RPiet::CodelChooser.new
  end

  it "knows its size" do
    @group.size.should == 30
  end

  it "can pick the right points" do
    @group.point_for(@dp, @cc).should == [8, 5] # dp: RIGHT cc: LEFT  -> UR
    @cc.switch! # LEFT -> RIGHT
    @group.point_for(@dp, @cc).should == [8, 6] # dp: RIGHT cc: RIGHT  -> LR
    @dp.rotate! # dp: RIGHT -> DOWN
    @cc.switch! # cc: RIGHT -> LEFT
    @group.point_for(@dp, @cc).should == [0, 7] # dp: DOWN cc: LEFT -> LR
    @cc.switch! # cc: LEFT -> RIGHT
    @group.point_for(@dp, @cc).should == [0, 7] # dp: DOWN cc: RIGHT -> LL
    @dp.rotate! # dp: DOWN -> LEFT
    @cc.switch! # cc: RIGHT -> LEFT
    @group.point_for(@dp, @cc).should == [0, 7] # dp: LEFT cc: LEFT -> LL
    @cc.switch! # cc: LEFT -> RIGHT
    @group.point_for(@dp, @cc).should == [0, 3] # dp: LEFT cc: RIGHT -> UL
    @dp.rotate! # dp: LEFT -> UP
    @cc.switch! 
    @group.point_for(@dp, @cc).should == [0, 3] # dp: UP cc: LEFT -> UL
    @cc.switch! # cc: LEFT -> RIGHT
    @group.point_for(@dp, @cc).should == [4, 3] # dp: UP cc: RIGHT -> UR

    # Since last group only has single wide bottom let's try another
    @cc.switch! # cc: RIGHT -> LEFT
    @dp.rotate! 2 # dp: UP -> DOWN
    @group2.point_for(@dp, @cc).should == [7, 3] # dp: DOWN cc: LEFT -> LR
    @cc.switch! # cc: RIGHT -> LEFT
    @group2.point_for(@dp, @cc).should == [6, 3] # dp: DOWN cc: RIGHT -> LL
    
  end
end
