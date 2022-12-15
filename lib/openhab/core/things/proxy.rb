# frozen_string_literal: true

require "delegate"
require "forwardable"

module OpenHAB
  module Core
    module Things
      # Class is a proxy to underlying thing
      # @!visibility private
      class Proxy < Delegator
        extend Forwardable
        def_delegators :__getobj__, :class, :is_a?, :kind_of?

        # @!visibility private
        EVENTS = [Events::ThingAddedEvent::TYPE, Events::ThingUpdatedEvent::TYPE,
                  Events::ThingRemovedEvent::TYPE].freeze
        # @!visibility private
        UID_METHOD = :uid

        include Core::Proxy

        # Returns the list of channels associated with this Thing
        #
        # @note This is defined on this class, and not on {Thing}, because
        #   that's the interface and if you define it there, it will be hidden
        #   by the method on ThingImpl.
        #
        # @return [Array] channels
        def channels
          Thing::ChannelsArray.new(super.to_a)
        end

        #
        # Set the proxy item (called by super)
        #
        def __setobj__(thing)
          @uid = thing.uid
        end

        #
        # Lookup thing from thing registry
        #
        def __getobj__
          $things.get(@uid)
        end

        #
        # Need to check if `self` _or_ the delegate is an instance of the
        # given class
        #
        # So that {#==} can work
        #
        # @return [true, false]
        #
        # @!visibility private
        def instance_of?(klass)
          __getobj__.instance_of?(klass) || super
        end

        #
        # Check if delegates are equal for comparison
        #
        # Otherwise items can't be used in Java maps
        #
        # @return [true, false]
        #
        # @!visibility private
        def ==(other)
          return __getobj__ == other.__getobj__ if other.instance_of?(Proxy)

          super
        end

        #
        # Non equality comparison
        #
        # @return [true, false]
        #
        # @!visibility private
        def !=(other)
          !(self == other) # rubocop:disable Style/InverseMethods
        end
      end
    end
  end
end
