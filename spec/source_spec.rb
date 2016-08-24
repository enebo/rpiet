require 'rpiet/source'
require 'rpiet/image/ascii_image'

describe "RPiet::Source" do
  let(:image) do
    RPiet::Image::AsciiImage.new <<-EOS
nb db db db ly
nb db db ly ly
ng db db ly ly
ng db db ly ly
ng db db ly ly
ng lg lg lg ++
  EOS
  end

  let(:source1) { RPiet::Source.new image }

  it "knows its size" do
    expect(source1.rows).to eq(6)
    expect(source1.cols).to eq(5)
    expect(source1.groups.size).to eq(6)
  end
end