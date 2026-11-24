# frozen_string_literal: true

module OpenHAB
  module RSpec
    #
    # Contains configuration for how the openHAB instance should be set
    # up for the testing environment.
    #
    module Configuration
      class << self
        # Location of the private Karaf test instance.
        #
        # Default `.karaf` in the current working directory.
        # @return [String]
        attr_accessor :karaf_path

        #
        # Copy binding configuration from the root openHAB instance.
        #
        # Default `true`.
        # @return [true, false]
        #
        attr_accessor :include_bindings

        #
        # Copy the JSONDB (managed thing and item configuration) from the root
        # openHAB instance.
        #
        # Default `true`.
        #
        # @return [true, false]
        #
        attr_accessor :include_jsondb

        #
        # Use a private (empty) confdir (scripts, rules, items, and things
        # files), instead of sharing with the root openHAB instance.
        #
        # Default `false`.
        #
        # @return [true, false]
        #
        attr_accessor :private_confdir

        #
        # Use the root openHAB instance directly, rather than creating a
        # private (but linked) instance.
        #
        # Default `false`.
        #
        # @return [true, false]
        #
        attr_accessor :use_root_instance
      end

      self.karaf_path = nil
      self.include_bindings = true
      self.include_jsondb = true
      self.private_confdir = false
      self.use_root_instance = false
    end
  end
end
