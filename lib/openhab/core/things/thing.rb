# frozen_string_literal: true

module OpenHAB
  module Core
    module Things
      # @interface
      java_import org.openhab.core.thing.Thing

      #
      # A {Thing} is a representation of a connected part (e.g. physical device
      # or cloud service) from the real world. It contains a list of
      # {Channel Channels}, which can be bound to {Item Items}.
      #
      # @see OpenHAB::DSL.things things[]
      # @see EntityLookup
      #
      # @example
      #   thing = things["chromecast:audiogroup:dd9f8622-eee-4eaf-b33f-cdcdcdeee001121"]
      #   logger.info("Audiogroup Status: #{thing&.status}")
      #   logger.info("Audiogroup Online? #{thing&.online?}")
      #   logger.info("Channel ids: #{thing.channels.map(&:uid)}")
      #   logger.info("Items linked to volume channel: #{thing.channels['volume']&.items&.map(&:name)&.join(', ')}")
      #   logger.info("Item linked to volume channel: #{thing.channels['volume']&.item&.name}")
      #
      # @example Thing actions can be called directly through a Thing object
      #   things["mqtt:broker:mosquitto"].publish_mqtt("zigbee2mqttt/bridge/config/permit_join", "true")
      #   things["mail:smtp:local"].send_mail("me@example.com", "Subject", "Email body")
      #
      # @example Thing can be accessed directly through {EntityLookup entity lookup}
      #   # replace ':' with '_' in thing uid
      #   mqtt_broker_mosquitto.online? # is mqtt:broker:mosquitto thing online?
      #
      # @!attribute [r] status
      #   Return the {https://www.openhab.org/docs/concepts/things.html#thing-status thing status}
      #   @return [org.openhab.core.thing.ThingStatus]
      #
      # @!attribute [r] channels
      #   @return [ChannelsArray]
      #
      # @!attribute [r] uid
      #   Return the UID.
      #   @return [ThingUID]
      #
      # @!attribute [r] bridge_uid
      #   Return the Bridge UID when available.
      #   @return [ThingUID]
      #
      # @!attribute [r] thing_type_uid
      #   @return [ThingTypeUID]
      #
      # @!attribute [r] configuration
      #   Return the thing's configuration.
      #   @return [OpenHAB::Core::Configuration]
      #
      #   @example
      #     logger.info things["smtp:mail:local"].configuration["hostname"]
      #     logger.info things["ipcamera:dahua:frontporch"].configuration["ipAddress"]
      #
      # @!attribute [r] properties
      #   Return the properties when available.
      #   @return [Hash]
      #
      #   @example
      #     logger.info things["fronius:meter:mybridge:mymeter"].properties["modelId"]
      #
      module Thing
        # Array wrapper class to allow searching a list of channels
        # by channel id
        class ChannelsArray < Array
          def initialize(thing, array)
            super(array)
            @thing = thing
          end

          # Allows indexing by both integer as an array or channel id acting like a hash.
          # @param [Integer, String, ChannelUID] index
          #   Numeric index, string channel id, or a {ChannelUID} to search for.
          # @return [Channel, nil]
          def [](index)
            return @thing.get_channel(index) if index.is_a?(ChannelUID)
            return @thing.get_channel(index.to_str) if index.respond_to?(:to_str)

            super
          end
        end

        class << self
          # @!visibility private
          #
          # Override to support Proxy
          #
          def ===(other)
            other.is_a?(self)
          end
        end

        #
        # @!method uninitialized?
        #   Check if thing status == UNINITIALIZED
        #   @return [true,false]
        #

        #
        # @!method initialized?
        #   Check if thing status == INITIALIZED
        #   @return [true,false]
        #

        #
        # @!method unknown?
        #   Check if thing status == UNKNOWN
        #   @return [true,false]
        #

        #
        # @!method online?
        #   Check if thing status == ONLINE
        #   @return [true,false]
        #

        #
        # @!method offline?
        #   Check if thing status == OFFLINE
        #   @return [true,false]
        #

        #
        # @!method removing?
        #   Check if thing status == REMOVING
        #   @return [true,false]
        #

        #
        # @!method removed?
        #   Check if thing status == REMOVED
        #   @return [true,false]
        #

        ThingStatus.constants.each do |thingstatus|
          define_method(:"#{thingstatus.to_s.downcase}?") { status == ThingStatus.value_of(thingstatus) }
        end

        #
        # Enable the Thing
        #
        # @param [true, false] enabled
        # @return [void]
        #
        def enable(enabled: true)
          Things.manager.set_enabled(uid, enabled)
        end

        #
        # Disable the Thing
        #
        # @return [void]
        #
        def disable
          enable(enabled: false)
        end

        # @!attribute [r] thing_type
        # @return [ThingType]
        def thing_type
          ThingType.registry.get_thing_type(thing_type_uid)
        end

        # @!attribute [r] bridge
        # @return [Thing, nil]
        def bridge
          bridge_uid && EntityLookup.lookup_thing(bridge_uid)
        end

        # @return [String]
        def inspect
          r = "#<OpenHAB::Core::Things::Thing #{uid}"
          r += " #{label.inspect}" if label
          r += " (#{location.inspect})" if location
          r += " #{status}"
          unless status_info.status_detail == org.openhab.core.thing.ThingStatusDetail::NONE
            r += " (#{status_info.status_detail})"
          end
          r += " configuration=#{configuration.properties.to_h}" unless configuration.properties.empty?
          r += " properties=#{properties.to_h}" unless properties.empty?
          "#{r}>"
        end

        #
        # Return Thing's uid as a string
        #
        # @return [String]
        #
        def to_s
          uid.to_s
        end

        # @return [org.openhab.core.common.registry.Provider, nil]
        def provider
          Provider.registry.provider_for(uid)
        end

        #
        # Fetches the actions available for this thing.
        #
        # Default scope actions are available directly on the thing object, via
        # {#method_missing}.
        #
        # @param [String, nil] scope The action scope. Default's to the thing's binding.
        # @return [Object, nil]
        #
        # @example
        #   things["max:thermostat:mybridge:thermostat"].actions("max-devices").delete_from_cube
        #
        # @example (see #method_missing)
        #
        def actions(scope = nil)
          $actions.get(scope || uid.binding_id, uid.to_s)
        end

        #
        # Compares all attributes of the thing with another thing.
        #
        # @param other [Thing] The thing to compare with
        # @return [true,false] true if all attributes are equal, false otherwise
        #
        def config_eql?(other)
          # @deprecated OH3.4 - in OH4, channels can be included in the array and do not need to be compared separately
          channels.to_a == other.channels.to_a &&
            %i[uid label bridge_uid location configuration].all? { |method| send(method) == other.send(method) }
        end

        #
        # Delegate missing methods to the thing's default actions scope.
        #
        # @example
        #   things['mail:smtp:local'].send_email('me@example.com', 'subject', 'message')
        #
        def method_missing(method, *args, &block)
          return actions.public_send(method, *args, &block) if actions.respond_to?(method)

          super
        end

        # @!visibility private
        def respond_to_missing?(method_name, _include_private = false)
          logger.trace("Checking if Thing #{uid} supports #{method_name} action")
          return true if actions.respond_to?(method_name)

          super
        end
      end
    end
  end
end
