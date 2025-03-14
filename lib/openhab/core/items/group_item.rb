# frozen_string_literal: true

require "openhab/core/lazy_array"

require_relative "generic_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.items.GroupItem

      #
      # A group behaves like a regular item, but also has {#members} which are
      # nested items that can be enumerated.
      #
      # If the group has a particular type, the methods from that type are
      # directly available.
      #
      #
      # The examples all assume the following items exist.
      # ```xtend
      # Group House
      # // Location perspective
      # Group GroundFloor  (House)
      # Group Livingroom   (GroundFloor)
      # // Functional perspective
      # Group Sensors      (House)
      # Group Temperatures (Sensors)
      #
      # Number Livingroom_Temperature "Living Room temperature" (Livingroom, Temperatures)
      # Number Bedroom_Temp "Bedroom temperature" (GroundFloor, Temperatures)
      # Number Den_Temp "Den temperature" (GroundFloor, Temperatures)
      # ```
      #
      # @!attribute [r] base_item
      #   @return [Item, nil] A typed item if the group has a particular type.
      #
      # @example Operate on items in a group using enumerable methods
      #   logger.info("Total Temperatures: #{Temperatures.members.count}")
      #   # Total Temperatures: 3
      #   logger.info("Temperatures: #{House.members.map(&:name).sort.join(', ')}")
      #   # Temperatures: GroundFloor, Sensors
      #
      # @example Access to the methods and attributes like any item
      #   logger.info("Group: #{Temperatures.name}" # Group: Temperatures'
      #
      # @example Operates on items in nested groups using enumerable methods
      #   logger.info("House Count: #{House.all_members.count}")
      #   # House Count: 7
      #   logger.info("Items: #{House.all_members.grep_v(GroupItem).map(&:label).sort.join(', ')}")
      #   # Items: Bedroom temperature, Den temperature, Living Room temperature
      #
      # @example Iterate through the direct members of the group
      #   Temperatures.members.each do |item|
      #     logger.info("#{item.label} is: #{item.state}")
      #   end
      #   # Living Room temperature is 22
      #   # Bedroom temperature is 21
      #   # Den temperature is 19
      #
      # @example
      #   rule 'Turn off any switch that changes' do
      #     changed Switches.members
      #     triggered(&:off)
      #   end
      #
      # @example Built in {Enumerable} functions can be applied to groups.
      #   logger.info("Max is #{Temperatures.members.map(&:state).max}")
      #   logger.info("Min is #{Temperatures.members.map(&:state).min}")
      #
      class GroupItem < GenericItem
        #
        # Class for indicating to triggers that a group trigger should be used
        #
        class Members
          include LazyArray

          # @return [GroupItem]
          attr_reader :group

          # @!visibility private
          def initialize(group_item)
            @group = group_item
          end

          #
          # Adds a member to the group
          #
          # @param [Item, String] member The item to add to the group
          # @return [Members] self
          #
          def add(member)
            if member.is_a?(String)
              member = items[member]
              raise ArgumentError, "Item not found: #{member}" if member.nil?
            end

            member = member.__getobj__ if member.is_a?(Proxy)
            raise ArgumentError, "Member must be an Item" unless member.is_a?(Item)

            group.add_member(member)
            self
          end
          alias_method :<<, :add

          # Explicit conversion to Array
          #
          # @return [Array]
          def to_a
            group.get_members.map { |i| Proxy.new(i) }
          end

          # Name of the group
          #
          # @return [String]
          def name
            group.name
          end

          # @return [String]
          def inspect
            r = "#<OpenHAB::Core::Items::GroupItems::Members #{name}"
            r += " #{map(&:name).inspect}" unless @group.__getobj__.nil?
            "#{r}>"
          end
          alias_method :to_s, :inspect
        end

        # @!attribute [r] function
        # @return [GroupFunction] Returns the function of this GroupItem

        # Override because we want to send them to the base item if possible
        %i[command update].each do |method|
          define_method(method) do |command, **kwargs|
            return base_item.__send__(method, command, **kwargs) if base_item

            super(command, **kwargs)
          end
        end

        #
        # @!attribute [r] members
        # @return [Members] Get an Array-like object representing the members of the group
        #
        # @see Enumerable
        #
        def members
          Members.new(Proxy.new(self))
        end

        #
        # @!attribute [r] all_members
        # @return [Array] Get all non-group members of the group recursively.
        #
        # @see Enumerable
        #
        def all_members
          getAllMembers.map { |m| Proxy.new(m) }
        end

        # give the base item type a chance to format commands
        # @!visibility private
        def format_type(command)
          return super unless base_item

          base_item.format_type(command)
        end

        %w[call color contact date_time dimmer image location number player rollershutter string switch].each do |type|
          type_class = type.gsub(/(^[a-z]|_[a-z])/) { |letter| letter[-1].upcase }
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{type}_item?                      # def date_time_item?
              base_item&.is_a?(#{type_class}Item)  #   base_item&.is_a?(DateTimeItem)
            end                                    # end
          RUBY
        end

        #
        # Compares all attributes of the item with another item.
        #
        # @param other [Item] The item to compare with
        # @return [true,false] true if all attributes are equal, false otherwise
        #
        # @!visibility private
        def config_eql?(other)
          return false unless super

          base_item&.type == other.base_item&.type && function&.inspect == other.function&.inspect
        end

        private

        # Add base type and function details
        def type_details
          r = ""
          r += ":#{base_item.type}#{base_item.__send__(:type_details)}" if base_item
          r += ":#{function.inspect}" if function && function.to_s != "EQUALITY"
          r
        end

        # Delegate missing methods to {base_item} if possible
        # Command methods and predicate methods for GroupItem are performed here
        # instead of being statically defined in items.rb
        # because base_item is needed to determine the command/data types but is not available in the static context
        def method_missing(method, ...)
          return base_item.__send__(method, ...) if base_item&.respond_to?(method) # rubocop:disable Lint/RedundantSafeNavigation -- nil responds to :to_a

          super
        end

        def respond_to_missing?(method, include_private = false)
          return true if base_item&.respond_to?(method) # rubocop:disable Lint/RedundantSafeNavigation

          super
        end
      end
    end
  end
end

# @!parse GroupItem = OpenHAB::Core::Items::GroupItem
