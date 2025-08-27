# frozen_string_literal: true

require "singleton"

require_relative "script_handling"

module OpenHAB
  module Core
    # rubocop:disable Naming/MethodName
    # @!visibility private
    class ProfileFactory
      include org.openhab.core.config.core.ConfigDescriptionProvider # This needs to be included first
      include org.openhab.core.thing.profiles.ProfileFactory
      include org.openhab.core.thing.profiles.ProfileTypeProvider
      include Singleton

      class Profile
        include org.openhab.core.thing.profiles.TimeSeriesProfile
        include org.openhab.core.thing.profiles.TriggerProfile

        def initialize(callback, context, uid, thread_locals, block)
          unless callback.class.ancestors.include?(Things::ProfileCallback)
            callback.class.prepend(Things::ProfileCallback)
            callback.class.field_reader :link
          end

          @callback = callback
          @context = context
          @uid = uid
          @thread_locals = thread_locals
          @block = block
        end

        # @!visibility private
        def getProfileTypeUID
          @uid
        end

        # @!visibility private
        def onCommandFromItem(command, source = nil)
          return unless process_event(:command_from_item, command:, source:) == true

          logger.trace("Forwarding original command")
          @callback.handle_command(command)
        end

        # @!visibility private
        def onStateUpdateFromHandler(state)
          return unless process_event(:state_from_handler, state:) == true

          logger.trace("Forwarding original update")
          @callback.send_update(state)
        end

        # @!visibility private
        def onCommandFromHandler(command)
          return unless process_event(:command_from_handler, command:) == true

          logger.trace("Forwarding original command")
          callback.send_command(command)
        end

        # @!visibility private
        def onStateUpdateFromItem(state)
          process_event(:state_from_item, state:)
        end

        # @!visibility private
        def onTriggerFromHandler(event)
          process_event(:trigger_from_handler, trigger: event)
        end

        # @!visibility private
        def onTimeSeriesFromHandler(time_series)
          process_event(:time_series_from_handler, time_series:)
        end

        private

        def process_event(event, **params)
          logger.trace do
            "Handling event #{event.inspect} in profile #{@uid} with param #{params.values.first.inspect}."
          end

          params[:callback] = @callback
          params[:context] = @context
          params[:configuration] = @context.configuration.properties
          params[:link] = @callback.link
          params[:item] = @callback.link.item
          params[:channel_uid] = @callback.link.linked_uid
          params[:state] ||= nil
          params[:command] ||= nil
          params[:trigger] ||= nil
          params[:time_series] ||= nil
          params[:source] ||= nil

          kwargs = {}
          @block.parameters.each do |(param_type, name)|
            case param_type
            when :keyreq, :key
              kwargs[name] = params[name] if params.key?(name)
            when :keyrest
              kwargs = params
            end
          end

          DSL::ThreadLocal.thread_local(**@thread_locals) do
            @block.call(event, **kwargs)
          rescue Exception => e
            raise if defined?(::RSpec)

            @block.binding.eval("self").logger.log_exception(e)
          end
        end
      end
      private_constant :Profile

      def initialize
        @profiles = {}
        @uri_to_uid = {}

        @registration = OSGi.register_service(self)
        ScriptHandling.script_unloaded { unregister }
      end

      #
      # Unregister the ProfileFactory OSGi service
      #
      # @!visibility private
      # @return [void]
      #
      def unregister
        @registration.unregister
      end

      # @!visibility private
      def register(id, block, label: nil, type: :state, config_description: nil)
        uid = org.openhab.core.thing.profiles.ProfileTypeUID.new("ruby", id)
        uri = java.net.URI.new("profile", uid.to_s, nil)
        if config_description && config_description.uid != uri
          config_description = org.openhab.core.config.core.ConfigDescriptionBuilder.create(uri)
                                  .with_parameters(config_description.parameters)
                                  .with_parameter_groups(config_description.parameter_groups)
                                  .build
        end

        @profiles[uid] = {
          thread_locals: DSL::ThreadLocal.persist,
          label:,
          type:,
          config_description:,
          block:
        }
        @uri_to_uid[uri] = uid
      end

      # @!visibility private
      def createProfile(uid, callback, context)
        profile = @profiles[uid]
        Profile.new(callback, context, uid, profile[:thread_locals], profile[:block])
      end

      # @!visibility private
      def getSupportedProfileTypeUIDs
        @profiles.keys
      end

      # @!visibility private
      def getProfileTypes(_locale)
        @profiles.filter_map do |uid, profile|
          next if profile[:label].nil?

          if profile[:type] == :trigger
            org.openhab.core.thing.profiles.ProfileTypeBuilder.new_trigger(uid, "RUBY #{profile[:label]}").build
          else
            org.openhab.core.thing.profiles.ProfileTypeBuilder.new_state(uid, "RUBY #{profile[:label]}").build
          end
        end
      end

      # @!visibility private
      def getConfigDescriptions(_locale)
        @profiles.values.filter_map { |profile| profile[:config_description] if profile[:label] }
      end

      # @!visibility private
      def getConfigDescription(uri, _locale)
        uid = @uri_to_uid[uri]
        @profiles.dig(uid, :config_description)
      end
    end
    # rubocop:enable Naming/MethodName
  end
end
