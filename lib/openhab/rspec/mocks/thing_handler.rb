# frozen_string_literal: true

# rubocop:disable Naming/AccessorMethodName

require "singleton"
require "jruby/core_ext/class"

module OpenHAB
  module RSpec
    module Mocks
      class ThingHandler
        include org.openhab.core.thing.binding.BridgeHandler

        attr_reader :thing

        # These helpers must also be visible to script engines in other Ruby runtimes.
        java_signature "org.openhab.core.thing.binding.ThingHandlerCallback callback()"
        def callback # rubocop:disable Style/TrivialAccessors
          @callback
        end

        def initialize(thing)
          @thing = thing
        end

        def initialize_handler
          status_info = org.openhab.core.thing.binding.builder.ThingStatusInfoBuilder
                           .create(org.openhab.core.thing.ThingStatus::ONLINE).build
          @callback.status_updated(thing, status_info)
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

        java_signature "void send_time_series(org.openhab.core.thing.ChannelUID, org.openhab.core.types.TimeSeries)"
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

        # Reification exports the helpers above as well as the complete Java interface.
        alias_method :getThing, :thing
        alias_method :setCallback, :set_callback
        alias_method :thingUpdated, :thing_updated
        alias_method :handleCommand, :handle_command
        alias_method :channelLinked, :channel_linked
        alias_method :channelUnlinked, :channel_unlinked
        alias_method :childHandlerInitialized, :child_handler_initialized
        alias_method :childHandlerDisposed, :child_handler_disposed
        java_signature "void initialize()"
        configure_java_class includes: [:initialize], proxy_dispatches: { initialize: :initialize_handler }
        become_java!
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
# rubocop:enable Naming/AccessorMethodName
