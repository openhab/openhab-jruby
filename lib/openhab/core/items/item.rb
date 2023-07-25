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
            if tag.is_a?(Semantics::SemanticTag)
              tag.name
            else
              tag
            end
          end
          !(self.tags.to_a & tags).empty?
        end

        # Return the item's thing if this item is linked with a thing. If an item is linked to more than one thing,
        # this method only returns the first thing.
        #
        # @return [Thing] The thing associated with this item or nil
        def thing
          all_linked_things.first
        end
        alias_method :linked_thing, :thing

        # Returns all of the item's linked things.
        #
        # @return [Array<Thing>] An array of things or an empty array
        def things
          registry = Things::Links::Provider.registry
          channels = registry.get_bound_channels(name).to_a
          channels.map(&:thing_uid).uniq.map { |tuid| EntityLookup.lookup_thing(tuid) }.compact
        end
        alias_method :all_linked_things, :things

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

        # @return [org.openhab.core.common.registry.Provider]
        def provider
          Provider.registry.provider_for(self)
        end

        private

        # Allows sub-classes to append additional details to the type in an inspect string
        # @return [String]
        def type_details; end
      end
    end
  end
end

# @!parse Item = OpenHAB::Core::Items::Item
