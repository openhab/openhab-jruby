# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::CallItem do
  subject(:item) { CallOne }

  before do
    items.build do
      group_item "Calls" do
        call_item "CallOne"
        call_item "CallTwo"
      end
    end
  end

  it "is a call item" do
    expect(item).to be_a_call_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  it "works with grep" do
    items.build { switch_item "SwitchOne" }
    expect(items.grep(CallItem)).to match_array [CallOne, CallTwo]
  end
end
