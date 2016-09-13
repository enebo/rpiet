require 'rpiet/source'
require 'rpiet/image/ascii_image'
require 'rpiet/color'

describe "RPiet::Source" do
  let(:image) do
    RPiet::Image::AsciiImage.new <<-EOS
nb db db db ly
nb db db ly ly
ng db db ly ly
ng db db ly ly
ng db db ly ..
ng lg lg lg ++
  EOS
  end

  let(:source1) { RPiet::Source.new image }

  it "knows its size" do
    expect(source1.rows).to eq(6)
    expect(source1.cols).to eq(5)
    expect(source1.groups.size).to eq(7)
  end

  it "#valid? knows invalid locations" do
    expect(source1.valid?(-1, 0)).to be_falsey
    expect(source1.valid?(0, -1)).to be_falsey
    expect(source1.valid?(source1.cols, 0)).to be_falsey
    expect(source1.valid?(0, source1.rows)).to be_falsey
    expect(source1.valid?(4, 5)).to be_falsey  # black codel
  end

  it "#valid? knows valid locations" do
    expect(source1.valid?(0, 0)).to be_truthy
    expect(source1.valid?(source1.cols-1, 0)).to be_truthy
    expect(source1.valid?(0, source1.rows-1)).to be_truthy
    expect(source1.valid?(4, 4)).to be_truthy  # white codel
  end

  it "#group_at knows which group it is associated with" do
    expect(source1.group_at(0, 0).color).to eq(RPiet::Color::BLUE)
    expect(source1.group_at(1, 0).color).to eq(RPiet::Color::DARK_BLUE)
    expect(source1.group_at(2, 0).color).to eq(RPiet::Color::DARK_BLUE)
    expect(source1.group_at(4, 0).color).to eq(RPiet::Color::LIGHT_YELLOW)
    expect(source1.group_at(4, 4).color).to eq(RPiet::Color::WHITE)
    expect(source1.group_at(3, 5).color).to eq(RPiet::Color::LIGHT_GREEN)
    expect(source1.group_at(4, 5).color).to eq(RPiet::Color::BLACK)
  end
end