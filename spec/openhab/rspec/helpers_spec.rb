# frozen_string_literal: true

# rubocop:disable RSpec/NamedSubject I need to use the implicit subject
RSpec.describe OpenHAB::RSpec::Helpers do
  describe "load_rules" do
    it "respects start levels" do
      allow(::RSpec.configuration).to receive(:openhab_automation_search_paths).and_return(["automation"])
      allow(Dir).to receive(:[]).and_return(%w[automation/filea.rb automation/sl30/filec.rb
                                               automation/filea.sl20.rb automation/sl30/fileb.rb])

      # rubocop:disable RSpec/SubjectStub
      expect(subject).to receive(:load).with("automation/filea.sl20.rb").ordered
      expect(subject).to receive(:load).with("automation/sl30/fileb.rb").ordered
      expect(subject).to receive(:load).with("automation/sl30/filec.rb").ordered
      expect(subject).to receive(:load).with("automation/filea.rb").ordered
      # rubocop:enable RSpec/SubjectStub
      subject.load_rules
    end
  end

  describe "autoupdate_all_items" do
    it "works" do
      items.build { switch_item "Switch1", autoupdate: false }

      Switch1.on
      expect(Switch1).to be_null

      autoupdate_all_items
      Switch1.on
      expect(Switch1).to be_on
    end
  end
end
# rubocop:enable RSpec/NamedSubject
