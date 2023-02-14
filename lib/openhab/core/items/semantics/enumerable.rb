# frozen_string_literal: true

#
# Additions to Enumerable to allow easily filtering and commanding groups of items.
#
# @example Turn on all members of a group
#   gOutsideLights.members.on
#
# @example Turn on all lights that are tagged `NightLights`
#   items.tagged("NightLights").on
#
# @example Close all blinds in the same room when the TV is turned on
#   rule "Close Blinds" do
#     changed gTVPower.members, to: ON
#     triggered do |item|
#       item.location
#           .equipments(Semantics::Blinds)
#           .points(Semantics::OpenLevel)
#           .down
#     end
#   end
#
# @example {OpenHAB::DSL::Items::Ensure::Ensurable Ensure} works on Enumerable
#   gLights.members.ensure.on
#   # or
#   gLights.members.ensure << ON
#
# @example Send a command to a list of items
#   [Light1, Light2, Light3].on
#   # or
#   [Light1, Light2, Light3].command(ON) # can't use <<, because that's already defined on Array
#
# @see OpenHAB::Core::Items::Semantics Semantics
#

module Enumerable
  #
  # @!group Filtering Methods
  #   Methods to help filter the members of the Enumerable
  #

  # Returns a new array of items that have at least one of the given tags
  # @return [Array<Item>]
  def tagged(*tags)
    reject { |i| (tags & i.tags.to_a).empty? }
  end

  # Returns a new array of items that do not have any of the given tags
  # @return [Array<Item>]
  def not_tagged(*tags)
    select { |i| (tags & i.tags.to_a).empty? }
  end

  # Returns a new array of items that are a member of at least one of the given groups
  # @return [Array<Item>]
  def member_of(*groups)
    reject { |i| (groups.map(&:name) & i.group_names).empty? }
  end

  # Returns a new array of items that are not a member of any of the given groups
  # @return [Array<Item>]
  def not_member_of(*groups)
    select { |i| (groups.map(&:name) & i.group_names).empty? }
  end

  # Returns the group members of all group elements
  # @return [Array<Item>]
  def members
    grep(OpenHAB::Core::Items::GroupItem).flat_map(&:members).uniq
  end

  # Returns all non-group members of all group elements, recursively
  # @return [Array<Item>]
  def all_members
    grep(OpenHAB::Core::Items::GroupItem).flat_map(&:all_members).uniq
  end

  # Returns the groups of all elements
  # @return [Array<GroupItem>]
  def groups
    flat_map(&:groups).uniq
  end

  # Returns all groups all elements are a part of, recursively
  # @return [Array<GroupItem>]
  def all_groups
    flat_map(&:all_groups).uniq
  end

  # @!group Items State and Command Methods

  # Send a command to every item in the collection
  # @return [self, nil] nil when `ensure` is in effect and all the items were already in the same state,
  #   otherwise self
  def command(command)
    self if count { |i| i.command(command) }.positive?
  end

  # Update the state of every item in the collection
  # @return [self, nil] nil when `ensure` is in effect and all the items were already in the same state,
  #   otherwise self
  def update(state)
    self if count { |i| i.update(state) }.positive?
  end

  # @!method refresh
  #   Send the {REFRESH} command to every item in the collection
  #   @return [self]

  # @!method on
  #   Send the {ON} command to every item in the collection
  #   @return [self]

  # @!method off
  #   Send the {OFF} command to every item in the collection
  #   @return [self]

  # @!method up
  #   Send the {UP} command to every item in the collection
  #   @return [self]

  # @!method down
  #   Send the {DOWN} command to every item in the collection
  #   @return [self]

  # @!method stop
  #   Send the {STOP} command to every item in the collection
  #   @return [self]

  # @!method move
  #   Send the {MOVE} command to every item in the collection
  #   @return [self]

  # @!method increase
  #   Send the {INCREASE} command to every item in the collection
  #   @return [self]

  # @!method decrease
  #   Send the {DECREASE} command to every item in the collection
  #   @return [self]

  # @!method play
  #   Send the {PLAY} command to every item in the collection
  #   @return [self]

  # @!method pause
  #   Send the {PAUSE} command to every item in the collection
  #   @return [self]

  # @!method rewind
  #   Send the {REWIND} command to every item in the collection
  #   @return [self]

  # @!method fast_forward
  #   Send the {FASTFORWARD} command to every item in the collection
  #   @return [self]

  # @!method next
  #   Send the {NEXT} command to every item in the collection
  #   @return [self]

  # @!method previous
  #   Send the {PREVIOUS} command to every item in the collection
  #   @return [self]

  # @!visibility private
  # can't use `include`, because Enumerable has already been included
  # in other classes
  def ensure
    OpenHAB::DSL::Items::Ensure::ItemDelegate.new(self)
  end
end
