# frozen_string_literal: true

# rubocop:disable RSpec/IdenticalEqualityAssertion
RSpec.describe OpenHAB::Core::Items::Proxy do
  before do
    items.build { switch_item "Switch1" }
  end

  it "uses the same instance every time it's accessed" do
    expect(Switch1).to be Switch1
    expect(Switch1).to eql Switch1
    expect(Switch1.__getobj__).to be Switch1.__getobj__
    expect(Switch1.hash).to eql Switch1.hash
  end

  it "can be used in a Java map" do
    map = java.util.concurrent.ConcurrentHashMap.new
    map.put(Switch1, 1)
    expect(map.get(Switch1)).to be 1
  end

  it "can be used in a Hash" do
    hash = {}
    hash[Switch1] = 1
    expect(hash[Switch1]).to be 1
  end

  it "can be used in a Set" do
    set = Set.new
    set << Switch1
    expect(set).to include(Switch1)
  end

  it "still works with replaced items" do
    original = Switch1
    original_actual = original.__getobj__

    items.remove("Switch1")
    expect(original.__getobj__).to be_nil
    expect { Switch1 }.to raise_error(NameError)

    items.build { switch_item "Switch1" }

    new_item = Switch1
    # same instance
    expect(original).to be new_item
    # but it now refers to the new underlying item
    expect(new_item.__getobj__).not_to be_nil
    expect(original_actual).not_to be original.__getobj__
    expect(original.__getobj__).to be new_item.__getobj__
  end

  # rubocop:disable Lint/UselessAssignment
  it "doesn't keep referenced items alive internally that disappear before the item is removed" do
    # so we can't break the WeakRef before the `removed` callback is called on the registry listener
    skip "Broken because we have a ref to the item internally in Items::Provider"
    original = Switch1
    original = nil
    GC.start

    items.remove("Switch1")
    expect(described_class.instance_variable_get(:@proxies)).to be_empty
  end

  it "doesn't keep referenced items alive internally that disappear after the item is removed" do
    original = Switch1

    items.remove("Switch1")

    original_item_actual = original.__getobj__
    original = nil
    GC.start

    items.build { switch_item "Switch1" }

    # we got a new instance, because the WeakRef was dead when
    # we go to fetch Switch1 again
    expect(original_item_actual).not_to be Switch1.__getobj__
  end
  # rubocop:enable Lint/UselessAssignment

  context "without a backing item" do
    let(:item) { described_class.new(:MySwitch) }

    it "supports #name" do
      expect(item.name).to eq "MySwitch"
    end

    it "pretends to be an item" do
      expect(item).to be_a(Item)
    end

    it "can access GroupItem#members" do
      expect(item.members).to be_a(GroupItem::Members)
    end

    it "doesn't respond to other Item methods" do
      expect(item).not_to respond_to(:command)
      expect { item.command }.to raise_error(NoMethodError)
    end
  end

  it "does not respond to GroupItem#members if it's backed by a non-GroupItem" do
    expect(Switch1).not_to respond_to(:members)
    expect { Switch1.members }.to raise_error(NoMethodError)
  end

  describe "Comparisons" do
    before do
      items.build { switch_item "Switch2" }
    end

    it "can be done with ==" do
      expect(Switch1).to eq Switch1
      expect(Switch1).not_to eq Switch2
    end

    it "can be done with !=" do
      expect(Switch1 != Switch2).to be true
      expect(Switch1 != Switch1).to be false # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
    end
  end
end
# rubocop:enable RSpec/IdenticalEqualityAssertion
