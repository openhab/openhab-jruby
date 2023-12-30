# frozen_string_literal: true

require "forwardable"

require_relative "uid"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.ChannelGroupUID

      #
      # {ChannelGroupUID} represents a unique identifier for a group of channels.
      #
      # @!attribute [r] id
      #   @return [String]
      #
      # @!attribute [r] thing_uid
      #   @return [ThingUID]
      #
      class ChannelGroupUID < UID
      end
    end
  end
end
