# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::DimmerItem do
  subject(:item) { DimmerOne }

  before do
    items.build do
      group_item "Dimmers" do
        dimmer_item "DimmerOne", state: 50
        dimmer_item "DimmerTwo", state: 50
      end
    end
  end

  it "is not a color" do
    expect(item).not_to be_a_color_item
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

  describe "#accepted_command_types" do
    it "returns Ruby classes" do
      expect(DimmerOne.accepted_data_types).to eql [PercentType, OnOffType, UnDefType]
    end
  end

  it "sends on/off commands" do
    Dimmers.members.each { |d| d.update(OFF) }
    Dimmers.members.each(&:on)
    expect(DimmerOne.state).to eql PercentType::HUNDRED
    expect(DimmerTwo.state).to eql PercentType::HUNDRED

    Dimmers.members.each(&:off)
    expect(DimmerOne.state).to eql PercentType::ZERO
    expect(DimmerTwo.state).to eql PercentType::ZERO
  end

  it "supports on?/off? predicates" do
    expect(item).to be_on
    expect(item).not_to be_off
    item.update(0)
    expect(item).not_to be_on
    expect(item).to be_off
  end

  describe "#dim and #brighten" do
    specify do
      item.dim 2
      expect(item.state).to eq 48
    end

    specify do
      item.brighten 2
      expect(item.state).to eq 52
    end

    specify do
      item.dim
      expect(item.state).to eq 49
    end

    specify do
      item.brighten
      expect(item.state).to eq 51
    end
  end

  describe "#increase and #decrease" do
    %i[increase decrease].each do |method|
      it "sends #{method} command" do
        received = nil
        received_command item do |event|
          received = event.command
        end

        item.send(method)
        expect(received.to_s).to eql method.to_s.upcase
      end
    end
  end

  describe "#toggle" do
    specify do
      item.on.toggle
      expect(item.state).to eq 0
    end

    specify do
      item.off.toggle
      expect(item.state).to eq 100
    end

    specify do
      item.update(UNDEF).toggle
      expect(item.state).to eq 100
    end

    specify do
      item.update(NULL).toggle
      expect(item.state).to eq 100
    end
  end

  it "works with grep" do
    items.build { switch_item "Switch1" }
    expect(items.grep(DimmerItem)).to match_array [DimmerOne, DimmerTwo]
  end
end
