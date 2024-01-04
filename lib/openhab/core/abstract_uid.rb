# frozen_string_literal: true

module OpenHAB
  module Core
    java_import org.openhab.core.common.AbstractUID

    # A non specific base class for unique identifiers.
    class AbstractUID
      # implicit conversion to string
      alias_method :to_str, :to_s
      # inspect result is just the string representation
      alias_method :inspect, :to_s

      # compares if equal to `other`, including string conversion
      # @return [true, false]
      def ==(other)
        return true if equals(other)

        to_s == other
      end
    end

    # have to remove == from all descendant classes so that they'll inherit
    # the new implementation
    [org.openhab.core.items.MetadataKey,
     org.openhab.core.thing.UID,
     org.openhab.core.thing.ChannelUID,
     org.openhab.core.thing.ChannelGroupUID,
     org.openhab.core.thing.ThingUID,
     org.openhab.core.thing.ThingTypeUID,
     org.openhab.core.thing.type.ChannelTypeUID,
     org.openhab.core.thing.type.ChannelGroupTypeUID].each do |klass|
      klass.remove_method(:==)
    end
  end
end
