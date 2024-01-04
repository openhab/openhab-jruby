# frozen_string_literal: true

require_relative "../abstract_uid"

module OpenHAB
  module Core
    module Things
      java_import org.openhab.core.thing.UID

      #
      # Base class for binding related unique identifiers.
      #
      # A UID must always start with a binding ID.
      #
      # @!attribute [r] binding_id
      #   @return [String]
      #
      # @!attribute [r] category
      #   (see ChannelGroupType#category)
      #
      class UID < AbstractUID
      end
    end
  end
end
