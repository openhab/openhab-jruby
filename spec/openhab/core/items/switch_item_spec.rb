# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::SwitchItem do
  subject(:item) { SwitchOne }

  before { items.build { switch_item "SwitchOne" } }

  it "is not a color" do
    expect(item).not_to be_a_color_item
  end

  it "is not a dimmer" do
    expect(item).not_to be_a_dimmer_item
  end

  it "is a switch" do
    expect(item).to be_a_switch_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  describe "commands" do
    specify { expect(item.on).to be_on }
    specify { expect(item.off).to be_off }
  end

  it "accepts boolean values" do
    expect((item << true).state).to be ON
    expect((item << false).state).to be OFF
  end

  describe "#toggle" do
    specify do
      item.on.toggle
      expect(item.state).to be OFF
    end

    specify do
      item.off.toggle
      expect(item.state).to be ON
    end

    specify do
      item.update(UNDEF).toggle
      expect(item.state).to be ON
    end

    specify do
      item.update(NULL).toggle
      expect(item.state).to be ON
    end

    it "accepts a source" do
      source = nil
      received_command(item) { |event| source = event.source }

      item.update(UNDEF).toggle(source: "undef")
      expect(source).to eq "undef"

      item.on.toggle(source: "on")
      expect(source).to eq "on"

      item.off.toggle(source: "off")
      expect(source).to eq "off"
    end
  end

  it "works with grep" do
    items.build { string_item "StringOne" }
    expect(items.grep(SwitchItem)).to eql [item]
  end
end
