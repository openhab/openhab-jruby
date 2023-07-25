# frozen_string_literal: true

module OpenHAB
  #
  # This module contains helper methods, hooks, and infrastracture to
  # boot openHAB inside of JRuby, and run RSpec (or other Ruby processes)
  # in that context.
  #
  # @see file:testing.md Testing Your Rules
  #
  module RSpec
    Object.include Helpers if defined?(IRB)

    # @!visibility private
    module Hooks
      class << self
        attr_accessor :cache_script_extension
      end
      self.cache_script_extension = nil
    end

    Helpers.launch_karaf(
      include_bindings: Configuration.include_bindings,
      include_jsondb: Configuration.include_jsondb,
      private_confdir: Configuration.private_confdir,
      use_root_instance: Configuration.use_root_instance
    )

    if defined?(::RSpec)
      ::RSpec.configure do |config|
        require_relative "example_group"
        config.include ExampleGroup

        config.before(:suite) do
          if config.mock_framework.framework_name == :rspec
            require_relative "mocks/instance_method_stasher"
            require_relative "mocks/space"
          end

          Helpers.autorequires unless Configuration.private_confdir
          Helpers.send(:set_up_autoupdates)
          Helpers.load_transforms
          Helpers.load_rules

          if DSL.shared_cache
            Hooks.cache_script_extension = OSGi.service(
              "org.openhab.core.automation.module.script.ScriptExtensionProvider",
              filter:
                "(component.name=org.openhab.core.automation.module.script.rulesupport.internal.CacheScriptExtension)"
            )
            Hooks.cache_script_extension.class.field_reader :sharedCache
          end
        end

        config.before do
          suspend_rules do
            $ir.for_each do |_provider, item|
              next if item.is_a?(GroupItem) # groups only have calculated states

              item.state = NULL unless item.raw_state == NULL
            end
          end
        end

        # Each spec gets temporary providers
        [Core::Items::Provider,
         Core::Items::Metadata::Provider,
         Core::Items::Semantics::Provider,
         Core::Rules::Provider,
         Core::Things::Provider,
         Core::Things::Links::Provider].each do |klass|
          config.around do |example|
            klass.new(&example)
          end
        end

        config.before do |example|
          # clear persisted thing status
          tm = Core::Things.manager
          tm.class.field_reader :disabledStorage
          tm.disabledStorage.keys.each { |k| tm.disabledStorage.remove(k) } # rubocop:disable Style/HashEachMethods not a hash
          @profile_factory = Core::ProfileFactory.send(:new)
          allow(Core::ProfileFactory).to receive(:instance).and_return(@profile_factory)

          stub_const("OpenHAB::Core::Timer", Mocks::Timer) if self.class.mock_timers?

          log_line = "rspec #{example.location} # #{example.full_description}"
          logger.info(log_line)
          Logger.events.info(log_line)
          @log_index = File.size(log_file)
        end

        config.after do
          @profile_factory.unregister
          timers.cancel_all
          # timers and rules have already been canceled, so we can safely just
          # wipe this
          DSL::Items::TimedCommand.timed_commands.clear
          Timecop.return
          restore_autoupdate_items
          Mocks::PersistenceService.instance.reset
          Hooks.cache_script_extension.sharedCache.clear if DSL.shared_cache
          DSL.persistence!(nil)
        end
      end
    end
  end
end
