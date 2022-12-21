# frozen_string_literal: true

require "singleton"

require_relative "script_handling"

module OpenHAB
  module Core
    # @!visibility private
    class ProfileFactory
      include org.openhab.core.thing.profiles.ProfileFactory
      include Singleton

      # rubocop:disable Naming/MethodName
      class Profile
        include org.openhab.core.thing.profiles.StateProfile

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
        def onCommandFromItem(command)
          return unless process_event(:command_from_item, command: command) == true

          logger.trace("Forwarding original command")
          @callback.handle_command(command)
        end

        # @!visibility private
        def onStateUpdateFromHandler(state)
          return unless process_event(:state_from_handler, state: state) == true

          logger.trace("Forwarding original update")
          @callback.send_update(state)
        end

        # @!visibility private
        def onCommandFromHandler(command)
          return unless process_event(:command_from_handler, command: command) == true

          logger.trace("Forwarding original command")
          callback.send_command(command)
        end

        # @!visibility private
        def onStateUpdateFromItem(state)
          process_event(:state_from_item, state: state)
        end

        private

        def process_event(event, **params)
          logger.trace("Handling event #{event.inspect} in profile #{@uid} with param #{params.values.first.inspect}.")

          params[:callback] = @callback
          params[:context] = @context
          params[:configuration] = @context.configuration.properties
          params[:link] = @callback.link
          params[:item] = @callback.link.item
          params[:channel_uid] = @callback.link.linked_uid
          params[:state] ||= nil
          params[:command] ||= nil

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
      # rubocop:enable Naming/MethodName

      def initialize
        @profiles = {}

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
      def register(uid, block)
        @profiles[uid] = [DSL::ThreadLocal.persist, block]
      end

      def createProfile(type, callback, context) # rubocop:disable Naming/MethodName
        @profiles[type].then { |(thread_locals, block)| Profile.new(callback, context, type, thread_locals, block) }
      end

      def getSupportedProfileTypeUIDs # rubocop:disable Naming/MethodName
        @profiles.keys
      end
    end
  end
end
