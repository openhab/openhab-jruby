# frozen_string_literal: true

RSpec.describe "Items" do
  context "with in-spec created items" do
    # Has to be in after(:all) so that the top-level after hook has run;
    # this example group explicitly has a single spec
    after(:all) do # rubocop:disable RSpec/BeforeAfterAll
      expect(items["MyItem"]).to be_nil
    end

    it "cleans up all items created in a spec" do
      items.build do
        switch_item "MyItem"
      end
    end
  end
end
