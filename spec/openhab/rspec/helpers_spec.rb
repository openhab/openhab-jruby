# frozen_string_literal: true

require "tmpdir"

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
    [false, true].each do |raise_error|
      it "restores thread locals between files#{" even when loading fails" if raise_error}" do
        allow(RSpec.configuration).to receive(:openhab_automation_search_paths).and_return(["automation"])
        allow(Dir).to receive(:[]).and_return(%w[automation/a.rb automation/b.rb])
        original = OpenHAB::DSL::ThreadLocal.persist
        allow(subject).to receive(:load).with("automation/a.rb") do
          OpenHAB::DSL::ThreadLocal::KNOWN_KEYS.each { |key| Thread.current[key] = :changed }
          raise "Failed script" if raise_error
        end
        second_file_states = []
        allow(subject).to receive(:load).with("automation/b.rb") do
          second_file_states << OpenHAB::DSL::ThreadLocal.persist
        end
        allow(subject).to receive(:warn) if raise_error

        OpenHAB::DSL::ThreadLocal.thread_local(**original) do
          subject.load_rules
          expect(second_file_states).to eq [original]
          expect(OpenHAB::DSL::ThreadLocal.persist).to eq original
        end
      end
    end

    it "keeps file settings in rules without suppressing repeated updates in examples" do
      items.build do
        number_item "Source593"
        switch_item "Target593"
      end

      Dir.mktmpdir do |directory|
        File.write("#{directory}/mirror.rb", <<~RUBY)
          ensure_states!
          rule "mirror593" do
            updated Source593
            run { Target593.command(ON) if Thread.current[:openhab_ensure_states] }
          end
        RUBY
        allow(RSpec.configuration).to receive(:openhab_automation_search_paths).and_return([directory])

        OpenHAB::DSL::ThreadLocal.thread_local(openhab_ensure_states: false) do
          subject.load_rules
          Source593.update(1)
          expect(Target593).to be_on
          Target593.update(OFF)
          Source593.update(1)
          expect(Target593).to be_on
        end
      end
    end

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
