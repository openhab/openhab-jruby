# frozen_string_literal: true

RSpec.describe OpenHAB::Log do
  OpenHAB::Logger::LEVELS.each do |level|
    describe "##{level}?" do
      it "works" do
        expect { logger.send(:"#{level}?") }.not_to raise_error
      end
    end

    describe "##{level}" do
      it "works" do
        logger.send(level, "log line")
        expect(spec_log_lines).to include(match(/#{level.to_s.upcase}.* log line/))
      end

      it "accepts a block" do
        logger.send(level) { "Message in a Block" }
        expect(spec_log_lines).to include(match(/#{level.to_s.upcase}.* Message in a Block/))
      end
    end
  end

  describe "#name" do
    before do
      stub_const("MyClass", Class.new do
        class << self
          def logger_name
            logger.name
          end
        end

        def logger_name
          logger.name
        end
      end)
    end

    it "uses the file name at the top level" do
      expect(logger.name).to eql "org.openhab.automation.jrubyscripting.log_spec"
    end

    it "uses Object when it happens to be an object with nothing else" do
      expect(Object.new.logger.name).to eql "org.openhab.automation.jrubyscripting.Object"
    end

    it "includes the rule id inside a rule" do
      rspec = self
      rule "log test", id: "log_test" do
        rspec.expect(logger.name).to rspec.eql "org.openhab.automation.jrubyscripting.log_spec.rule.log_test"
        on_load
        run do
          expect(logger.name).to eql "org.openhab.automation.jrubyscripting.log_spec.rule.log_test"
        end
      end

      rule "log test with uid" do
        uid "log_test2"
        on_load
        run do
          expect(logger.name).to eql "org.openhab.automation.jrubyscripting.log_spec.rule.log_test2"
        end
      end
    end

    it "uses the rule id inside a timer block inside a rule" do
      executed = false
      logger_name = nil
      rule "log test" do
        on_load
        run do
          after(1.second) do
            executed = true
            logger_name = logger.name
          end
        end
      end
      time_travel_and_execute_timers(5.seconds)
      expect(logger_name).to match(/^org\.openhab\.automation\.jrubyscripting\.log_spec\.rule\.log_spec:(?:\d+)$/)
      expect(executed).to be true
    end

    it "uses the rule id inside a script block" do
      executed = false
      script "my script", id: "my_script" do
        executed = true
        expect(logger.name).to eql "org.openhab.automation.jrubyscripting.log_spec.script.my_script"
      end
      rules["my_script"].trigger
      expect(executed).to be true
    end

    it "uses the profile name inside a profile block" do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"

      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
      end

      executed = false
      profile "use_a_different_state" do
        executed = true
        expect(logger.name).to eql "org.openhab.automation.jrubyscripting.log_spec.profile.use_a_different_state"
      end

      items.build do
        string_item "MyString",
                    channel: ["astro:sun:home:season#name", { profile: "ruby:use_a_different_state" }],
                    autoupdate: false
      end

      MyString << "foo"
      expect(executed).to be true
    end

    it "uses the file name inside a timer block" do
      file_logger_name = logger.name
      executed = false
      after(1.second) do
        executed = true
        expect(logger.name).to eql file_logger_name
      end

      time_travel_and_execute_timers(5.seconds)
      expect(executed).to be true
    end

    it "uses the class name inside a class method" do
      expect(MyClass.logger_name).to eql "org.openhab.automation.jrubyscripting.MyClass"
      expect(MyClass.new.logger_name).to eql "org.openhab.automation.jrubyscripting.MyClass"
    end

    it "uses the class name inside a class method inside a rule" do
      rule "my rule" do
        on_load
        run do
          expect(MyClass.logger_name).to eql "org.openhab.automation.jrubyscripting.MyClass"
          expect(MyClass.new.logger_name).to eql "org.openhab.automation.jrubyscripting.MyClass"
        end
      end
    end

    it "uses the external file prefix" do
      require_relative "log_module"

      expect(mylib_logger_name).to eql "org.openhab.automation.jrubyscripting.log_module"
    end

    it "uses the class name inside external libraries" do
      require_relative "log_module"

      expect(LogModule::MyClass.logger.name).to eql "org.openhab.automation.jrubyscripting.LogModule.MyClass"
    end

    it "uses the class name inside external libraries inside a rule" do
      require_relative "log_module"

      items.build { string_item "TestItem" }

      logger_name = nil
      received_command(TestItem) { |event| logger_name = event.logger_name }

      TestItem << "foo"
      expect(logger_name).to eql(
        "org.openhab.automation.jrubyscripting.org.openhab.core.items.events.ItemCommandEvent"
      )
    end
  end
end
