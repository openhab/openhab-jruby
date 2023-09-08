# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::ColorItem do
  subject(:item) do
    items.build do
      color_item "Color", state: HSBType::BLACK
    end
  end

  it "is a color" do
    expect(item).to be_a_color_item
  end

  it "is a dimmer" do
    expect(item).to be_a_dimmer_item
  end

  it "is a switch" do
    expect(item).to be_a_switch_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  it "can be updated to an HSBType" do
    item << HSBType.new(0, 100, 100)
    expect(item.state).to eq HSBType.new("0,100,100")
  end

  it "can be updated to an HSBType from RGB" do
    item << HSBType.from_rgb(255, 0, 0)
    expect(item.state).to eq HSBType.new("0,100,100")
  end

  [
    "0,100,100",
    "#FF0000"
  ].each do |command|
    it "can be updated to #{command}" do
      item << command
      expect(item.state).to eq HSBType.new("0,100,100")
    end
  end
end
