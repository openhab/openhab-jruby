# frozen_string_literal: true

require "delegate"
require "forwardable"

require_relative "thing"
require_relative "thing_uid"

module OpenHAB
  module Core
    module Things
      # Class is a proxy to underlying thing
      # @!visibility private
      class Proxy < Delegator
        extend Forwardable

        def_delegators :__getobj__, :class, :is_a?, :kind_of?

        # @!visibility private
        EVENTS = [Events::ThingAddedEvent::TYPE,
                  Events::ThingUpdatedEvent::TYPE,
                  Events::ThingRemovedEvent::TYPE].freeze
        # @!visibility private
        UID_METHOD = :uid
        # @!visibility private
        UID_TYPE = ThingUID

        include Core::Proxy

        # @return [ThingUID]
        attr_reader :uid

        # Returns the list of channels associated with this Thing
        #
        # @note This is defined on this class, and not on {Thing}, because
        #   that's the interface and if you define it there, it will be hidden
        #   by the method on ThingImpl.
        #
        # @return [Array] channels
        def channels
          Thing::ChannelsArray.new(self, super.to_a)
        end

        # Returns the properties of this Thing
        #
        # @note This is defined on this class, and not on {Thing}, because
        #   that's the interface and if you define it there, it will be hidden
        #   by the method on ThingImpl.
        #
        # @return [Thing::Properties] properties map
        def properties
          Thing::Properties.new(self)
        end
      end
    end
  end
end
