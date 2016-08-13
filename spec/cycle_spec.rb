require 'rpiet/cycle'

module A
  extend RPiet::CycleMethod
  cycle :Letter, :A, :B, :C
end

describe "RPiet::Cycle" do
  it "can do cycle addition" do
    expect(A::Letter::A + A::Letter::A).to eq(A::Letter::A)
    expect(A::Letter::A + A::Letter::B).to eq(A::Letter::B)
    expect(A::Letter::A + A::Letter::C).to eq(A::Letter::C)
    expect(A::Letter::B + A::Letter::A).to eq(A::Letter::B)
    expect(A::Letter::B + A::Letter::B).to eq(A::Letter::C)
    expect(A::Letter::B + A::Letter::C).to eq(A::Letter::A)
    expect(A::Letter::C + A::Letter::A).to eq(A::Letter::C)
    expect(A::Letter::C + A::Letter::B).to eq(A::Letter::A)
    expect(A::Letter::C + A::Letter::C).to eq(A::Letter::B)
  end

  it "can do cycle subtraction" do
    expect(A::Letter::A - A::Letter::A).to eq(A::Letter::A)
    expect(A::Letter::A - A::Letter::B).to eq(A::Letter::C)
    expect(A::Letter::A - A::Letter::C).to eq(A::Letter::B)
    expect(A::Letter::B - A::Letter::A).to eq(A::Letter::B)
    expect(A::Letter::B - A::Letter::B).to eq(A::Letter::A)
    expect(A::Letter::B - A::Letter::C).to eq(A::Letter::C)
    expect(A::Letter::C - A::Letter::A).to eq(A::Letter::C)
    expect(A::Letter::C - A::Letter::B).to eq(A::Letter::B)
    expect(A::Letter::C - A::Letter::C).to eq(A::Letter::A)
  end

  it "can increment" do
    expect(A::Letter::A.incr).to eq(A::Letter::B)
    expect(A::Letter::B.incr).to eq(A::Letter::C)
    expect(A::Letter::C.incr).to eq(A::Letter::A)
  end

  it "can decrement" do
    expect(A::Letter::A.decr).to eq(A::Letter::C)
    expect(A::Letter::B.decr).to eq(A::Letter::A)
    expect(A::Letter::C.decr).to eq(A::Letter::B)
  end

  it "can calculate deltas" do
    expect(A::Letter::A.delta(A::Letter::A)).to eq(0)
    expect(A::Letter::A.delta(A::Letter::B)).to eq(2)
    expect(A::Letter::A.delta(A::Letter::C)).to eq(1)
    expect(A::Letter::B.delta(A::Letter::A)).to eq(1)
    expect(A::Letter::B.delta(A::Letter::B)).to eq(0)
    expect(A::Letter::B.delta(A::Letter::C)).to eq(2)
    expect(A::Letter::C.delta(A::Letter::A)).to eq(2)
    expect(A::Letter::C.delta(A::Letter::B)).to eq(1)
    expect(A::Letter::C.delta(A::Letter::C)).to eq(0)
  end
end
