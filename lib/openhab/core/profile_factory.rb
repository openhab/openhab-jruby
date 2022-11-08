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

        def initialize(callback, context, uid, block)
          unless callback.class.ancestors.include?(Things::ProfileCallback)
            callback.class.prepend(Things::ProfileCallback)
            callback.class.field_reader :link
          end

          @callback = callback
          @context = context
          @uid = uid
          @block = block
        end

        # @!visibility private
        def getProfileTypeUID
          @uid
        end

        # @!visibility private
        def onCommandFromItem(command)
          return unless process_event(:command_from_item, command: command) == true

          @callback.handle_command(command)
        end

        # @!visibility private
        def onStateUpdateFromHandler(state)
          return unless process_event(:state_from_handler, state: state) == true

          @callback.send_update(state)
        end

        # @!visibility private
        def onCommandFromHandler(command)
          return unless process_event(:command_from_handler, command: command) == true

          callback.send_command(command)
        end

        # @!visibility private
        def onStateUpdateFromItem(state)
          process_event(:state_from_item, state: state)
        end

        private

        def process_event(event, **params)
          params[:callback] = @callback
          params[:context] = @context
          params[:config] = @context.configuration
          params[:link] = @callback.link
          params[:item] = @callback.link.item
          params[:channel_uid] = @callback.link.linked_uid

          kwargs = {}
          @block.parameters.each do |(param_type, name)|
            case param_type
            when :keyreq, :key
              kwargs[name] = params[name] if params.key?(name)
            when :keyrest
              kwargs = params
            end
          end

          DSL::ThreadLocal.thread_local(OPENHAB_RULE_UID: getProfileTypeUID.id) do
            @block.call(event, **kwargs)
          rescue Exception => e
            @block.binding.eval("self").logger.log_exception(e)
          end
        end
      end
      private_constant :Profile
      # rubocop:enable Naming/MethodName

      def initialize
        @profiles = {}
      end

      # @!visibility private
      def register(uid, block)
        @profiles[uid] = block
      end

      def createProfile(type, callback, context) # rubocop:disable Naming/MethodName
        @profiles[type].then { |block| Profile.new(callback, context, type, block) }
      end

      def getSupportedProfileTypeUIDs # rubocop:disable Naming/MethodName
        @profiles.keys
      end
    end

    # registration = OSGi.register_service(ProfileFactory.instance)
    # ScriptHandlingCallbacks.script_unloaded_hooks << -> { registration.unregister }
  end
end
