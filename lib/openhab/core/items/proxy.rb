# frozen_string_literal: true

require "delegate"
require_relative "../proxy"

module OpenHAB
  module Core
    module Items
      # Class is a proxy to underlying {Item}
      # @!visibility private
      class Proxy < Delegator
        # Not really an Item, but pretends to be
        # @!parse include Item

        # @!visibility private
        EVENTS = [Events::ItemAddedEvent::TYPE,
                  Events::ItemUpdatedEvent::TYPE,
                  Events::ItemRemovedEvent::TYPE].freeze
        # @!visibility private
        UID_METHOD = :name
        # @!visibility private
        UID_TYPE = String

        include Core::Proxy

        # @return [String]
        attr_reader :name

        # @return [Module]
        def class
          target = __getobj__
          return Item if target.nil?

          target.class
        end

        # @return [true, false]
        def is_a?(klass)
          target = __getobj__
          # only claim to be a Delegator if we're backed by an actual item at the moment
          klass == Item || target.is_a?(klass) || klass == Proxy || (target.nil? && super)
        end
        alias_method :kind_of?, :is_a?

        # @return [GroupItem::Members]
        # @raise [NoMethodError] if item is neither a GroupItem, nor a dummy.
        def members
          target = __getobj__
          return GroupItem::Members.new(self) if target.nil?

          target.members
        end

        # Several methods can just return nil when it's a dummy item
        # This helps when you're doing something like `items.locations.select {}`
        # when items are getting created and removed in a concurrent thread to
        # not have errors because an item disappeared
        %i[
          equipment
          equipment?
          equipment_type
          location
          location?
          location_type
          member_of?
          point?
          point_type
          property_type
          semantic?
          semantic_type
          tagged?
        ].each do |m|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{m}(*args)              # def equipment(*args)
              target = __getobj__        #   target = __getobj__
              return nil if target.nil?  #   return nil if target.nil?
                                         #
              target.#{m}(*args)         #   target.equipment(*args)
            end                          # end
          RUBY
        end

        # needs to return `true` for dummies for #members, false
        # for non-dummies that aren't actually groups
        def respond_to?(method, include_private = false) # rubocop:disable Style/OptionalBooleanParameter
          target = __getobj__
          if target.nil?
            return true if Item.method_defined?(method)
          elsif method.to_sym == :members
            return target.respond_to?(method)
          end

          target.respond_to?(method, include_private) || super
        end

        private

        # ditto
        def target_respond_to?(target, method, include_private)
          if method.to_sym == :members
            return true if target.nil?

            return target.respond_to?(method, include_private)
          end

          target.respond_to?(method, include_private)
        end
      end
    end
  end
end
