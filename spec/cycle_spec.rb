require 'rpiet/cycle'

module A
  extend RPiet::CycleMethod
  cycle :Letter, :A, :B, :C
end

describe "RPiet::Cycle" do
  it "can do cycle addition" do
    (A::Letter::A + A::Letter::A).should == A::Letter::A
    (A::Letter::A + A::Letter::B).should == A::Letter::B
    (A::Letter::A + A::Letter::C).should == A::Letter::C
    (A::Letter::B + A::Letter::A).should == A::Letter::B
    (A::Letter::B + A::Letter::B).should == A::Letter::C
    (A::Letter::B + A::Letter::C).should == A::Letter::A
    (A::Letter::C + A::Letter::A).should == A::Letter::C
    (A::Letter::C + A::Letter::B).should == A::Letter::A
    (A::Letter::C + A::Letter::C).should == A::Letter::B
  end

  it "can do cycle subtraction" do
    (A::Letter::A - A::Letter::A).should == A::Letter::A
    (A::Letter::A - A::Letter::B).should == A::Letter::C
    (A::Letter::A - A::Letter::C).should == A::Letter::B
    (A::Letter::B - A::Letter::A).should == A::Letter::B
    (A::Letter::B - A::Letter::B).should == A::Letter::A
    (A::Letter::B - A::Letter::C).should == A::Letter::C
    (A::Letter::C - A::Letter::A).should == A::Letter::C
    (A::Letter::C - A::Letter::B).should == A::Letter::B
    (A::Letter::C - A::Letter::C).should == A::Letter::A
  end

  it "can increment" do
    A::Letter::A.incr.should == A::Letter::B
    A::Letter::B.incr.should == A::Letter::C
    A::Letter::C.incr.should == A::Letter::A
  end

  it "can decrement" do
    A::Letter::A.decr.should == A::Letter::C
    A::Letter::B.decr.should == A::Letter::A
    A::Letter::C.decr.should == A::Letter::B
  end

  it "can calculate deltas" do
    A::Letter::A.delta(A::Letter::A).should == 0
    A::Letter::A.delta(A::Letter::B).should == 2
    A::Letter::A.delta(A::Letter::C).should == 1
    A::Letter::B.delta(A::Letter::A).should == 1
    A::Letter::B.delta(A::Letter::B).should == 0
    A::Letter::B.delta(A::Letter::C).should == 2
    A::Letter::C.delta(A::Letter::A).should == 2
    A::Letter::C.delta(A::Letter::B).should == 1
    A::Letter::C.delta(A::Letter::C).should == 0
  end
end
