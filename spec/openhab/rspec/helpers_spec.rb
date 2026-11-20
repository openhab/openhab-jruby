# frozen_string_literal: true

# rubocop:disable-next RSpec/NamedSubject -- I need to use the implicit subject
RSpec.describe OpenHAB::RSpec::Helpers do
  describe "trigger_event" do
    %w[command state].each do |kind|
      it "infers the event type from an item #{kind} event" do
        sent_event = OpenHAB::Core::Events::ItemEventFactory.public_send("create_#{kind}_event", "Light", ON, "rspec")
        received_events = []
        mismatched_events = []
        rule do
          event sent_event.topic, types: sent_event.type, source: "rspec"
          run { |event| received_events << event }
        end
        rule do
          event sent_event.topic, types: "ThingUpdatedEvent"
          run { |event| mismatched_events << event }
        end

        trigger_event(sent_event)

        expect(received_events.size).to eq 1
        expect(received_events.first.type).to eq sent_event.type
        expect(received_events.first.topic).to eq sent_event.topic
        expect(received_events.first.payload).to eq sent_event.payload
        expect(received_events.first.source).to eq "rspec"
        expect(mismatched_events).to be_empty
      end
    end
  end

  describe "load_rules" do
    it "respects start levels" do
      allow(RSpec.configuration).to receive(:openhab_automation_search_paths).and_return(["automation"])
      allow(Dir).to receive(:[]).and_return(%w[automation/filea.rb
                                               automation/sl10/nested/deep/filed.rb
                                               automation/sl30/filec.rb
                                               automation/filea.sl20.rb
                                               automation/sl30/fileb.rb])

      expect(subject).to receive(:load).with("automation/sl10/nested/deep/filed.rb").ordered
      expect(subject).to receive(:load).with("automation/filea.sl20.rb").ordered
      expect(subject).to receive(:load).with("automation/sl30/fileb.rb").ordered
      expect(subject).to receive(:load).with("automation/sl30/filec.rb").ordered
      expect(subject).to receive(:load).with("automation/filea.rb").ordered
      # rubocop:enable RSpec/SubjectStub
      subject.load_rules
    end
  end
end
