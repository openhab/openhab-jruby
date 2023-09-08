# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::StringItem do
  subject(:item) { StringOne }

  before do
    items.build do
      group_item "Strings" do
        string_item "StringOne", state: "Hello"
        string_item "StringTwo", state: "World!"
        string_item "StringThree"
      end
    end
  end

  it "is a string" do
    expect(item).to be_a_string_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  it "works with grep" do
    items.build { switch_item "SwitchOne" }
    expect(items.grep(StringItem)).to match_array [StringOne, StringTwo, StringThree]
  end
end
