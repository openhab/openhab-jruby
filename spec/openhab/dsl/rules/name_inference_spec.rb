# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Rules::NameInference do
  shared_examples "item trigger" do
    it "generates a useful name" do
      trigger = self.trigger
      r = rules.build { send(trigger, SwitchItem1) { nil } }
      expect(r.name).to eql "SwitchItem1 #{trigger}"
    end

    it "generates a useful name for multiple items" do
      trigger = self.trigger
      r = rules.build { send(trigger, SwitchItem1, SwitchItem2) { nil } }
      expect(r.name).to eql "SwitchItem1 or SwitchItem2 #{trigger}"
    end

    it "generates a useful name for a to:" do
      trigger = self.trigger
      r = rules.build { send(trigger, SwitchItem1, to: ON) { nil } }
      expect(r.name).to eql "SwitchItem1 #{trigger} to ON"
    end

    it "generates a useful name for two to: states" do
      trigger = self.trigger
      r = rules.build { send(trigger, SwitchItem1, to: [NULL, UNDEF]) { nil } }
      expect(r.name).to eql "SwitchItem1 #{trigger} to NULL or UNDEF"
    end

    it "generates a useful name for three to: states" do
      trigger = self.trigger
      r = rules.build { send(trigger, SwitchItem1, to: [NULL, UNDEF, OFF]) { nil } }
      expect(r.name).to eql "SwitchItem1 #{trigger} to NULL, UNDEF, or OFF"
    end

    it "generates a useful name for a range to:" do
      trigger = self.trigger
      r = rules.build { send(trigger, NumberItem1, to: 1..10) { nil } }
      expect(r.name).to eql "NumberItem1 #{trigger} to 1..10"
    end
  end

  context "with #changed" do
    let(:trigger) { :changed }

    include_examples "item trigger"

    it "generates a useful name for a from:" do
      trigger = self.trigger
      r = rules.build { send(trigger, SwitchItem1, from: ON) { nil } }
      expect(r.name).to eql "SwitchItem1 changed from ON"
    end

    it "generates a useful name for a from: and to:" do
      trigger = self.trigger
      r = rules.build { send(trigger, SwitchItem1, from: OFF, to: ON) { nil } }
      expect(r.name).to eql "SwitchItem1 changed from OFF to ON"
    end

    describe "trigger with duration generates a descriptive label" do
      context "with items" do
        it "works" do
          trigger = self.trigger
          r = rules.build { send(trigger, SwitchItem1, from: OFF, to: ON, for: 1.hour) { nil } }
          expect(r.triggers.first.label).to eql "SwitchItem1 changed from OFF to ON for PT1H"
        end
      end

      context "with things" do
        let(:thing) do
          things.build { thing "astro:sun:home", "Astro Sun Data" }
        end

        it "works" do
          trigger = self.trigger
          thing = self.thing
          r = rules.build do
            send(trigger, thing, from: :offline, to: :online, for: 1.hour) { nil }
          end
          expect(r.triggers.first.label).to eql "astro:sun:home changed from :offline to :online for PT1H"
        end
      end
    end
  end

  context "with #updated" do
    let(:trigger) { :updated }

    include_examples "item trigger"
  end

  context "with #received_command" do
    it "generates a useful name" do
      r = rules.build { received_command(SwitchItem1) { nil } }
      expect(r.name).to eql "SwitchItem1 received command"
    end

    it "generates a useful name with a command" do
      r = rules.build { received_command(SwitchItem1, command: ON) { nil } }
      expect(r.name).to eql "SwitchItem1 received command ON"
    end
  end

  context "with #on_start" do
    it "generates a useful name" do
      r = rules.build { on_start { nil } }
      expect(r.name).to eql "System Start Level reached 100 (complete)"
    end

    it "generates a useful name given an at_level symbol" do
      r = rules.build { on_start(at_level: :rules) { nil } }
      expect(r.name).to eql "System Start Level reached 40 (rules)"
    end

    it "generates a useful name given an at_level number" do
      r = rules.build { on_start(at_level: 30) { nil } }
      expect(r.name).to eql "System Start Level reached 30 (states)"
    end

    it "generates a useful name given multiple at_levels" do
      r = rules.build { on_start(at_levels: [30, 40]) { nil } }
      expect(r.name).to eql "System Start Level reached 30 (states) or 40 (rules)"
    end
  end

  context "with #every" do
    it "generates a useful name" do
      %i[second
         minute
         hour
         day
         week
         month
         year
         monday
         tuesday
         wednesday
         thursday
         friday
         saturday
         sunday].each do |frequency|
        r = rules.build { every(frequency) { nil } }
        expect(r.name).to eql "Every #{frequency}"
      end
    end

    it "generates a useful name with a duration" do
      r = rules.build { every(5.minutes) { nil } }
      expect(r.name).to eql "Every PT5M"
    end

    it "generates a useful name with an at:" do
      r = rules.build { every(:week, at: "12:00") { nil } }
      expect(r.name).to eql "Every week at 12:00"
    end

    it "generates a useful name with an offset" do
      r = rules.build { every(:day, at: DateTimeItem1, offset: 5.minutes) { nil } }
      expect(r.name).to eql "Every day at DateTimeItem1 +5m"

      r = rules.build { every(:day, at: DateTimeItem1, offset: -5.minutes) { nil } }
      expect(r.name).to eql "Every day at DateTimeItem1 -5m"
    end
  end

  context "with #at" do
    it "generates a useful name" do
      r = rule do
        at DateTimeItem1
        run { nil }
      end
      expect(r.name).to eql "At DateTimeItem1"
    end

    it "generates a useful name with an offset" do
      r = rule do
        at DateTimeItem1, offset: 5.minutes
        run { nil }
      end
      expect(r.name).to eql "At DateTimeItem1 +5m"

      r = rule do
        at DateTimeItem1, offset: -5.minutes
        run { nil }
      end
      expect(r.name).to eql "At DateTimeItem1 -5m"
    end
  end
end
