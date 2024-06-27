# frozen_string_literal: true

module OpenHAB
  module Core
    module Items
      # @interface
      java_import org.openhab.core.items.Item

      #
      # The core features of an openHAB item.
      #
      module Item
        class << self
          # @!visibility private
          #
          # Override to support {Proxy}
          #
          def ===(other)
            other.is_a?(self)
          end

          private

          # @!macro def_type_predicate
          #   @!method $1_item?
          #   Check if the item is a $1 item.
          #   @note If the item is a group item, it will also return true if the base item is a $1 item.
          #   @return [true,false]
          def def_type_predicate(type)
            type_class = type.to_s.gsub(/(^[a-z]|_[a-z])/) { |letter| letter[-1].upcase }
            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{type}_item?           # def date_time_item?
                is_a?(#{type_class}Item)  #   is_a?(DateTimeItem)
              end                         # end
            RUBY
          end
        end

        # @!attribute [r] name
        #   The item's name.
        #   @return [String]

        # @!attribute [r] accepted_command_types
        #   @return [Array<Class>] An array of {Command}s that can be sent as commands to this item

        # @!attribute [r] accepted_data_types
        #   @return [Array<Class>] An array of {State}s that can be sent as commands to this item

        #
        # The item's {GenericItem#label label} if one is defined, otherwise its {#name}.
        #
        # @return [String]
        #
        def to_s
          label || name
        end

        #
        # @!attribute [r] groups
        #
        # Returns all groups that this item is part of
        #
        # @return [Array<GroupItem>] All groups that this item is part of
        #
        def groups
          group_names.map { |name| EntityLookup.lookup_item(name) }.compact
        end

        #
        # Checks if this item is a member of at least one of the given groups.
        #
        # @param groups [String, GroupItem] the group to check membership in
        # @return [true, false]
        #
        # @example
        #   event.item.member_of?(gFullOn)
        #
        def member_of?(*groups)
          groups.map! do |group|
            group.is_a?(GroupItem) ? group.name : group
          end
          !(group_names & groups).empty?
        end

        #
        # @!attribute [r] all_groups
        #
        # Returns all groups that this item is a part of, as well as those groups' groups, recursively
        #
        # @return [Array<GroupItem>]
        #
        def all_groups
          result = []
          new_groups = Set.new(groups)

          until new_groups.empty?
            result.concat(new_groups.to_a)
            new_groups.replace(new_groups.flat_map(&:groups))
            # remove any groups we already have in the result to avoid loops
            new_groups.subtract(result)
          end

          result
        end

        # rubocop:disable Layout/LineLength

        # @!attribute [r] metadata
        # @return [Metadata::NamespaceHash]
        #
        # Access to the item's metadata.
        #
        # Both the return value of this method as well as the individual
        # namespaces can be treated as Hashes.
        #
        # Examples assume the following items:
        #
        # ```xtend
        # Switch Item1 { namespace1="value" [ config1="foo", config2="bar" ] }
        # String StringItem1
        # ```
        #
        # @example Check namespace's existence
        #   Item1.metadata["namespace"].nil?
        #   Item1.metadata.key?("namespace")
        #
        # @example Access item's metadata value
        #   Item1.metadata["namespace1"].value
        #
        # @example Access namespace1's configuration
        #   Item1.metadata["namespace1"]["config1"]
        #
        # @example Safely search for the specified value - no errors are raised, only nil returned if a key in the chain doesn't exist
        #   Item1.metadata.dig("namespace1", "config1") # => "foo"
        #   Item1.metadata.dig("namespace2", "config1") # => nil
        #
        # @example Set item's metadata value, preserving its config
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace1"].value = "new value"
        #   # Item1's metadata after: {"namespace1"=>["new value", {"config1"=>"foo", "config2"=>"bar"]}}
        #
        # @example Set item's metadata config, preserving its value
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace1"].replace({ "scooby"=>"doo" })
        #   # Item1's metadata after: {"namespace1"=>["value", {scooby="doo"}]}
        #
        # @example Set a namespace to a new value and config in one line
        #   # Item1's metadata before: {"namespace1"=>"value", {"config1"=>"foo", "config2"=>"bar"}}
        #   Item1.metadata["namespace1"] = "new value", { "scooby"=>"doo" }
        #   # Item1's metadata after: {"namespace1"=>["new value", {scooby="doo"}]}
        #
        # @example Set item's metadata value and clear its previous config
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace1"] = "new value"
        #   # Item1's metadata after: {"namespace1"=>"value" }
        #
        # @example Set item's metadata config, set its value to nil, and wiping out previous config
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace1"] = { "newconfig"=>"value" }
        #   # Item1's metadata after: {"namespace1"=>{"config1"=>"foo", "config2"=>"bar"}}
        #
        # @example Update namespace1's specific configuration, preserving its value and other config
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace1"]["config1"] = "doo"
        #   # Item1's metadata will be: {"namespace1"=>["value", {"config1"=>"doo", "config2"=>"bar"}]}
        #
        # @example Add a new configuration to namespace1
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace1"]["config3"] = "boo"
        #   # Item1's metadata after: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar", config3="boo"}]}
        #
        # @example Delete a config
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace1"].delete("config2")
        #   # Item1's metadata after: {"namespace1"=>["value", {"config1"=>"foo"}]}
        #
        # @example Add a namespace and set it to a value
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace2"] = "qx"
        #   # Item1's metadata after: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}], "namespace2"=>"qx"}
        #
        # @example Add a namespace and set it to a value and config
        #   # Item1's metadata before: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace2"] = "qx", { "config1"=>"doo" }
        #   # Item1's metadata after: {"namespace1"=>["value", {"config1"=>"foo", "config2"=>"bar"}], "namespace2"=>["qx", {"config1"=>"doo"}]}
        #
        # @example Enumerate Item1's namespaces
        #   Item1.metadata.each { |namespace, metadata| logger.info("Item1's namespace: #{namespace}=#{metadata}") }
        #
        # @example Add metadata from a hash
        #   Item1.metadata.merge!({"namespace1"=>{"foo", {"config1"=>"baz"} ], "namespace2"=>{"qux", {"config"=>"quu"} ]})
        #
        # @example Merge Item2's metadata into Item1's metadata
        #   Item1.metadata.merge!(Item2.metadata)
        #
        # @example Delete a namespace
        #   Item1.metadata.delete("namespace1")
        #
        # @example Delete all metadata of the item
        #   Item1.metadata.clear
        #
        # @example Does this item have any metadata?
        #   Item1.metadata.any?
        #
        # @example Store another item's state
        #   StringItem1.update "TEST"
        #   Item1.metadata["other_state"] = StringItem1.state
        #
        # @example Store event's state
        #   rule "save event state" do
        #     changed StringItem1
        #     run { |event| Item1.metadata["last_event"] = event.was }
        #   end
        #
        # @example If the namespace already exists: Update the value of a namespace but preserve its config; otherwise create a new namespace with the given value and nil config.
        #   Item1.metadata["namespace"] = "value", Item1.metadata["namespace"]
        #
        # @example Copy another namespace
        #   # Item1's metadata before: {"namespace2"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #   Item1.metadata["namespace"] = Item1.metadata["namespace2"]
        #   # Item1's metadata after: {"namespace2"=>["value", {"config1"=>"foo", "config2"=>"bar"}], "namespace"=>["value", {"config1"=>"foo", "config2"=>"bar"}]}
        #
        def metadata
          @metadata ||= Metadata::NamespaceHash.new(name)
        end
        # rubocop:enable Layout/LineLength

        #
        # Checks if this item has at least one of the given tags.
        #
        # @param tags [String, Module] the tag(s) to check
        # @return [true, false]
        #
        # @example
        #   event.item.tagged?("Setpoint")
        #
        # @example
        #   event.item.tagged?(Semantics::Switch)
        #
        def tagged?(*tags)
          tags.map! do |tag|
            # @deprecated OH3.4
            if tag.is_a?(Module)
              tag.simple_name
            elsif defined?(Semantics::SemanticTag) && tag.is_a?(Semantics::SemanticTag)
              tag.name
            else
              tag
            end
          end
          !(self.tags.to_a & tags).empty?
        end

        # @!attribute thing [r]
        # Return the item's thing if this item is linked with a thing. If an item is linked to more than one channel,
        # this method only returns the first thing.
        #
        # @return [Things::Thing, nil]
        def thing
          all_linked_things.first
        end
        alias_method :linked_thing, :thing

        # @!attribute things [r]
        # Returns all of the item's linked things.
        #
        # @return [Array<Things::Thing>] An array of things or an empty array
        def things
          Things::Links::Provider.registry.get_bound_things(name).map { |thing| Things::Proxy.new(thing) }
        end
        alias_method :all_linked_things, :things

        # @!attribute channel_uid [r]
        # Return the UID of the channel this item is linked to. If an item is linked to more than one channel,
        # this method only returns the first channel.
        #
        # @return [Things::ChannelUID, nil]
        def channel_uid
          channel_uids.first
        end

        # @!attribute channel_uids [r]
        # Return the UIDs of all of the channels this item is linked to.
        #
        # @return [Array<Things::ChannelUID>]
        def channel_uids
          Things::Links::Provider.registry.get_bound_channels(name)
        end

        # @!attribute channel [r]
        # Return the channel this item is linked to. If an item is linked to more than one channel,
        # this method only returns the first channel.
        #
        # @return [Things::Channel, nil]
        def channel
          channel_uids.first&.channel
        end

        # @!attribute channels [r]
        # Return all of the channels this item is linked to.
        #
        # @return [Array<Things::Channel>]
        def channels
          channel_uids.map(&:channel)
        end

        #
        # @!attribute links [r]
        # Returns all of the item's links (channels and link configurations).
        #
        # @return [ItemChannelLinks] An array of ItemChannelLink or an empty array
        #
        # @example Get the configuration of the first link
        #   LivingRoom_Light_Power.links.first.configuration
        #
        # @example Remove all managed links
        #   LivingRoom_Light_Power.links.clear
        #
        # @see link
        # @see unlink
        #
        def links
          ItemChannelLinks.new(name, Things::Links::Provider.registry.get_links(name))
        end

        #
        # @return [Things::ItemChannelLink, nil]
        #
        # @overload link
        #   Returns the item's link. If an item is linked to more than one channel,
        #   this method only returns the first link.
        #
        #   @return [Things::ItemChannelLink, nil]
        #
        # @overload link(channel, config = {})
        #
        #   Links the item to a channel.
        #
        #   @param [String, Things::Channel, Things::ChannelUID] channel The channel to link to.
        #   @param [Hash] config The configuration for the link.
        #
        #   @return [Things::ItemChannelLink] The created link.
        #
        #   @example Link an item to a channel
        #     LivingRoom_Light_Power.link("mqtt:topic:livingroom-light:power")
        #
        #   @example Link to a Thing's channel
        #     LivingRoom_Light_Power.link(things["mqtt:topic:livingroom-light"].channels["power"])
        #
        #   @example Specify a link configuration
        #     High_Temperature_Alert.link(
        #       "mqtt:topic:outdoor-thermometer:temperature",
        #       profile: "system:hysteresis",
        #       lower: "29 °C",
        #       upper: "30 °C")
        #
        #   @see links
        #   @see unlink
        #
        def link(channel = nil, config = nil)
          return Things::Links::Provider.registry.get_links(name).first if channel.nil? && config.nil?

          config ||= {}
          Core::Things::Links::Provider.create_link(self, channel, config).tap do |new_link|
            provider = Core::Things::Links::Provider.current
            if !(current_link = provider.get(new_link.uid))
              provider.add(new_link)
            elsif current_link.configuration != config
              provider.update(new_link)
            end
          end
        end

        #
        # Removes a link to a channel from managed link providers.
        #
        # @param [String, Things::Channel, Things::ChannelUID] channel The channel to remove the link to.
        #
        # @return [Things::ItemChannelLink, nil] The removed link, if found.
        # @raise [FrozenError] if the link is not managed by a managed link provider.
        #
        # @see link
        # @see links
        #
        def unlink(channel)
          link_to_delete = Things::Links::Provider.create_link(self, channel, {})
          provider = Things::Links::Provider.registry.provider_for(link_to_delete.uid)
          unless provider.is_a?(ManagedProvider)
            raise FrozenError,
                  "Cannot remove the link #{link_to_delete.uid} from non-managed provider #{provider.inspect}"
          end

          provider.remove(link_to_delete.uid)
        end

        # @return [String]
        def inspect
          s = "#<OpenHAB::Core::Items::#{type}Item#{type_details} #{name} #{label.inspect} state=#{raw_state.inspect}"
          s += " category=#{category.inspect}" if category
          s += " tags=#{tags.to_a.inspect}" unless tags.empty?
          s += " groups=#{group_names}" unless group_names.empty?
          meta = metadata.to_h
          s += " metadata=#{meta.inspect}" unless meta.empty?
          "#{s}>"
        end

        # @!attribute provider [r]
        # @return [org.openhab.core.common.registry.Provider, nil] Returns the provider for this item.
        def provider
          Provider.registry.provider_for(self)
        end

        #
        # Compares all attributes except metadata and channels/links of the item with another item.
        #
        # @param other [Item] The item to compare with
        # @return [true,false] true if all attributes are equal, false otherwise
        #
        # @!visibility private
        def config_eql?(other)
          # GenericItem#equals checks whether other has the same name and class
          return false unless equals(other)

          %i[label category tags group_names].all? do |method|
            # Don't use #send here. It is defined in GenericItem for sending commands
            public_send(method) == other.public_send(method)
          end
        end

        def_type_predicate(:call)
        def_type_predicate(:color)
        def_type_predicate(:contact)
        def_type_predicate(:date_time)
        # @note Color items are also considered dimmer items.
        def_type_predicate(:dimmer)
        def_type_predicate(:group)
        def_type_predicate(:image)
        def_type_predicate(:location)
        def_type_predicate(:number)
        def_type_predicate(:player)
        def_type_predicate(:rollershutter)
        def_type_predicate(:string)
        # @note Color and dimmer items are also considered switch items.
        def_type_predicate(:switch)

        private

        # Allows sub-classes to append additional details to the type in an inspect string
        # @return [String]
        def type_details; end
      end
    end
  end
end

# @!parse Item = OpenHAB::Core::Items::Item
