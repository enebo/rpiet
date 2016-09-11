require_relative 'spec_helper'
require 'rpiet/group'

include SpecHelper

describe "Group" do
  SQUARE = <<-EOS
.###.
.###.
.###.
  EOS

  WACKY = <<-EOS
.#.#.
#####
.#.#.
  EOS

  HOOKY = <<-EOS
.#.#.#
######
.#.#..
  EOS


  let(:square_group) { create_group('0x0000c0', SQUARE) }
  let(:wacky_group) { create_group('0x000000', WACKY) }
  let(:hooky_group) { create_group('0x0000ff', HOOKY) }

  it "knows its rgb" do
    expect(square_group.rgb).to eq '0x0000c0'
    expect(wacky_group.rgb).to eq '0x000000'
    expect(hooky_group.rgb).to eq '0x0000ff'
  end

  it "knows its size" do
    expect(square_group.size).to eq(9)
    expect(wacky_group.size).to eq(9)
    expect(hooky_group.size).to eq(11)
  end

  it 'picks the right points (wacky)' do
    expect(wacky_group.rr).to eq([4,1])
    expect(wacky_group.rl).to eq([4,1])
    expect(wacky_group.lr).to eq([0,1])
    expect(wacky_group.ll).to eq([0,1])
    expect(wacky_group.dr).to eq([1,2])
    expect(wacky_group.dl).to eq([3,2])
    expect(wacky_group.ur).to eq([3,0])
    expect(wacky_group.ul).to eq([1,0])
  end

  it 'picks the right points (simple)' do
    expect(square_group.rr).to eq([3,2])
    expect(square_group.rl).to eq([3,0])
    expect(square_group.lr).to eq([1,0])
    expect(square_group.ll).to eq([1,2])
    expect(square_group.dr).to eq([1,2])
    expect(square_group.dl).to eq([3,2])
    expect(square_group.ur).to eq([3,0])
    expect(square_group.ul).to eq([1,0])
  end

  it 'picks the right points (hooky)' do
    expect(hooky_group.rr).to eq([5,1])
    expect(hooky_group.rl).to eq([5,0])
    expect(hooky_group.lr).to eq([0,1])
    expect(hooky_group.ll).to eq([0,1])
    expect(hooky_group.dr).to eq([1,2])
    expect(hooky_group.dl).to eq([3,2])
    expect(hooky_group.ur).to eq([5,0])
    expect(hooky_group.ul).to eq([1,0])
  end
end
