# frozen_string_literal: true

# rubocop:disable Naming/MethodName, Naming/AccessorMethodName

require "singleton"

module OpenHAB
  module RSpec
    module Mocks
      class ThingHandler
        include org.openhab.core.thing.binding.BridgeHandler

        attr_reader :thing, :callback

        def initialize(thing = nil)
          # have to handle the interface method
          if thing.nil?
            status_info = org.openhab.core.thing.binding.builder.ThingStatusInfoBuilder
                             .create(org.openhab.core.thing.ThingStatus::ONLINE).build
            @callback.status_updated(self.thing, status_info)
            return
          end

          # ruby initializer here
          @thing = thing
        end

        def thing_updated(thing)
          @thing = thing
        end

        def handle_command(channel_uid, command)
          channel = thing.get_channel(channel_uid)
          return unless channel
          return if channel.auto_update_policy == org.openhab.core.thing.type.AutoUpdatePolicy::VETO

          callback&.state_updated(channel_uid, command) if command.is_a?(Core::Types::State)
        end

        def send_time_series(channel_uid, time_series)
          @callback&.send_time_series(channel_uid, time_series)
        end

        def set_callback(callback)
          @callback = callback
        end

        def child_handler_initialized(child_handler, child_thing); end
        def child_handler_disposed(child_handler, child_thing); end

        def channel_linked(_channel_uid); end
        def channel_unlinked(_channel_uid); end

        def dispose; end
      end

      class ThingHandlerFactory < org.openhab.core.thing.binding.BaseThingHandlerFactory
        include Singleton

        class ComponentContext
          include org.osgi.service.component.ComponentContext
          include Singleton

          def getBundleContext
            org.osgi.framework.FrameworkUtil.get_bundle(org.openhab.core.thing.Thing.java_class).bundle_context
          end
        end
        private_constant :ComponentContext

        def initialize
          super
          activate(ComponentContext.instance)
        end

        def supportsThingType(_type)
          true
        end

        def createHandler(thing)
          ThingHandler.new(thing)
        end
      end
    end
  end
end
# rubocop:enable Naming/MethodName, Naming/AccessorMethodName
