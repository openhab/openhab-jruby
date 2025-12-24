# frozen_string_literal: true

require "delegate"

module OpenHAB
  module Core
    module Events
      #
      # Represents the source of an event as a chain of delegated {Component Components}.
      #
      # This class behaves like a String representing the event source, but also provides
      # methods to access the individual components in the delegation chain.
      #
      # Starting from openHAB 5.1, the source can contain multiple components
      # that contain information about the delegation chain of the event.
      #
      # Each {Source::Component component} contains:
      # - {Source::Component#bundle bundle}: The module or app.
      #   For example: `org.openhab.automation.jrubyscripting` when a rule sends a command,
      #   or `org.openhab.core.io.rest` when a command comes from the REST API (UI).
      # - {Source::Component#actor actor}: Optional. The rule, user or thinguid
      #   (e.g., "lighting_rule", "mqtt:topic:livingroom-switch:switch4")
      #
      # @example Log commands with source information
      #   rule "Log item commands" do
      #     received_command MyItem
      #     run do |event|
      #       logger.info "#{MyItem.name} received command #{event.command} from: #{event.source}"
      #       logger.info "  Source components:"
      #       event.source.components.each_with_index do |component, index|
      #         logger.info "    #{index}: bundle=#{component.bundle}, actor=#{component.actor}"
      #       end
      #     end
      #   end
      #
      # @example Ignore commands from specific integrations
      #   rule "Ignore UI commands" do
      #     received_command MyItem
      #     run do |event|
      #       next if event.source.sender?("org.openhab.core.io.rest")
      #       # process the command
      #     end
      #   end
      #
      # @see https://www.openhab.org/docs/developer/utils/events.html#the-core-events
      # @see AbstractEvent#source
      # @see OpenHAB::DSL.profile
      #
      class Source < Delegator
        # The components in the event source delegation chain.
        # @return [Array<Component>]
        attr_reader :components

        #
        # Construct a new {Source} object.
        #
        # @overload initialize(source)
        #   @param [String] source The event source as a string.
        #
        # @overload initialize(components)
        #   @param [Array<Component>] components The components in the event source delegation chain.
        #
        def initialize(source_or_components) # rubocop:disable Lint/MissingSuper
          @components = if source_or_components.is_a?(Array)
                          @source = nil
                          source_or_components.dup
                        else
                          @source = -source_or_components
                          @source.split("=>").map { |s| Component.parse(s) }
                        end.freeze
        end

        #
        # Construct a new {Source} by adding an additional component to the delegation chain.
        #
        # @param [String] bundle The bundle (module, app, etc.) of the new component to add to the chain.
        # @param [String, nil] actor The actor (user, device, etc.) of the new component to add to the chain.
        # @return [Source]
        #
        def delegate(bundle, actor = nil)
          Source.new(components + [Component.build(bundle, actor)])
        end

        #
        # Check if the event was sent by the specified bundle or actor.
        #
        # Checks if any component matches the specified bundle or actor.
        #
        # @overload sender?(bundle_or_actor)
        #   @param [#===] bundle_or_actor
        #     The bundle (module, app, etc.) or actor (user, device, etc.) to check.
        #     If either a bundle or actor in any component in the source matches, this method returns true.
        #   @return [true, false]
        #
        # @overload sender?(bundle: nil, actor: nil)
        #   @param [#===] bundle
        #   @param [#===] actor
        #   @return [true, false]
        #
        def sender?(bundle_or_actor = nil, bundle: nil, actor: nil)
          unless bundle_or_actor || bundle || actor
            raise ArgumentError, "Specify one of bundle_or_actor, bundle or actor"
          end

          # rubocop:disable Style/CaseEquality
          components.any? do |sender|
            (bundle && bundle === sender.bundle) ||
              (actor && actor === sender.actor) ||
              (bundle_or_actor && bundle_or_actor === sender.bundle) ||
              (bundle_or_actor && bundle_or_actor === sender.actor)
          end
          # rubocop:enable Style/CaseEquality
        end

        #
        # @param [#===] bundle The bundle (module, app, etc.) to find the actor for.
        # @return [String, nil] the actor (user, device, etc.) for the specified bundle, if any.
        #
        def actor_for(bundle)
          components.find { |c| bundle === c.bundle }&.actor # rubocop:disable Style/CaseEquality
        end

        #
        # Construct a new {Source} without any components from the specified bundle.
        #
        # This is useful if you consider events from a specific bundle as sensitive,
        # and want to filter that component out from an untrusted sender.
        #
        # @overload reject(bundle)
        #   @param [#===] bundle The bundle (module, app, etc.) to reject.
        #   @return [Source] a new Source without any components from the specified bundle.
        #
        # @overload reject { |component| ... }
        #   @yieldparam [Component] component Each component in the delegation chain.
        #   @return [Source] a new Source without any components for which the block returns true.
        #
        def reject(bundle = nil, &)
          raise ArgumentError, "Either a bundle or a block must be given" unless bundle || block_given?

          Source.new(if block_given?
                       components.reject(&)
                     else
                       components.reject { |c| bundle === c.bundle } # rubocop:disable Style/CaseEquality
                     end)
        end

        # @attribute [r] source
        #
        # The event source as a string.
        #
        # @return [String]
        #
        def source
          @source ||= components.join("=>").freeze
        end

        # @attribute [r] bundle
        #
        # The bundle (module, app, etc.) of the initial component that sent the event.
        #
        # @return [String, nil]
        #
        def bundle
          components.first&.bundle
        end

        # @attribute [r] actor
        #
        # The actor (user, device, etc.) of the initial component that sent the event.
        #
        # @return [String, nil]
        #
        def actor
          components.first&.actor
        end

        alias_method :to_s, :source
        alias_method :to_str, :source
        alias_method :inspect, :source
        alias_method :__getobj__, :source

        # @return [true, false]
        def ==(other)
          return components == other.components if other.is_a?(Source)
          return to_s == other.to_str if other.respond_to?(:to_str)

          false
        end

        # @return [true, false]
        def !=(other)
          !(self == other) # rubocop:disable Style/InverseMethods
        end

        # @return [Integer, nil]
        def <=>(other)
          return 0 if self == other
          return nil unless other.respond_to?(:to_str)

          to_s <=> other.to_str
        end

        def eql?(other)
          other.is_a?(Source) && components == other.components
        end

        # @return [Integer]
        def hash
          components.hash
        end

        # Represents a single component in the event source delegation chain.
        class Component
          include Comparable

          # The bundle (module, app, etc.) that sent the event.
          # @return [String]
          attr_reader :bundle

          # The actor (user, device, etc.) that sent the event.
          # @return [String]
          attr_reader :actor

          class << self
            #
            # Parse a {Component} from its string representation.
            #
            # @param [String] component The string representation of the {Component}.
            # @return [Component]
            #
            def parse(component)
              new(*component.split("$", 2))
            end

            #
            # Build a {Component} from the specified bundle and actor.
            #
            # @param [String] bundle The bundle (module, app, etc.) that sent the event.
            # @param [String, nil] actor The actor (user, device, etc.) that sent the event.
            # @return [Component]
            #
            def build(bundle, actor = nil)
              if AbstractEvent.respond_to?(:build_source)
                # a bit round-about, but is necessary for argument validation
                # and escaping
                # Only present in openHAB 5.1+
                begin
                  parse(AbstractEvent.build_source(bundle, actor))
                rescue java.lang.IllegalArgumentException => e
                  raise ArgumentError, e.message
                end
              else
                new(bundle, actor)
              end
            end
          end

          # @return [String]
          def to_s
            if actor
              "#{bundle}$#{actor}"
            else
              bundle
            end
          end
          alias_method :to_str, :to_s

          # @return [true, false]
          def ==(other)
            return bundle == other.bundle && actor == other.actor if other.is_a?(Component)
            return to_s == other.to_str if other.respond_to?(:to_str)

            false
          end

          # @return [true, false]
          def !=(other)
            !(self == other) # rubocop:disable Style/InverseMethods
          end

          # @return [Integer, nil]
          def <=>(other)
            return 0 if self == other
            return nil unless other.respond_to?(:to_str)

            to_s <=> other.to_str
          end

          def eql?(other)
            other.is_a?(Component) && bundle == other.bundle && actor == other.actor
          end

          # @return [Integer]
          def hash
            [bundle, actor].hash
          end

          private

          def initialize(bundle, actor = nil)
            @bundle = bundle
            @actor = actor
          end
        end
      end
    end
  end
end
