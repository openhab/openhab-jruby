# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Rules::Terse do
  before do
    items.build { switch_item "TestSwitch" }
  end

  it "works" do
    this = self
    ran = false
    changed TestSwitch do
      ran = true
      expect(self).to be this
    end
    TestSwitch.on
    expect(ran).to be true
  end

  it "returns the rule object" do
    rule = changed(TestSwitch) { nil }
    expect(rule).to be_a OpenHAB::Core::Rules::Rule
  end

  it "requires a block" do
    expect { changed(TestSwitch) }.to raise_error(ArgumentError)
  end

  it "can also run on_load" do
    this = self
    ran = false
    changed TestSwitch, on_load: true do
      ran = true
      expect(self).to be this
    end
    expect(ran).to be true
  end

  it "can define the rule name" do
    rule = changed(TestSwitch, name: "Test") { nil }
    expect(rule.name).to eql "Test"
  end

  it "can define the rule description" do
    rule = changed(TestSwitch, description: "Test") { nil }
    expect(rule.description).to eql "Test"
  end

  it "can define the rule id" do
    rule = changed(TestSwitch, id: "Test") { nil }
    expect(rule.uid).to eql "Test"
  end

  it "can define the rule tags" do
    rule = changed(TestSwitch, tag: "Test") { nil }
    expect(rule.tags).to match_array ["Test"]

    rule = changed(TestSwitch, tag: Semantics::LivingRoom) { nil }
    expect(rule.tags).to match_array ["LivingRoom"]

    rule = changed(TestSwitch, tags: %w[Test1 Test2]) { nil }
    expect(rule.tags).to match_array %w[Test1 Test2]
  end
end
