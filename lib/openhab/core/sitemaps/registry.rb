# frozen_string_literal: true

require "singleton"

require_relative "provider"

module OpenHAB
  module Core
    module Sitemaps
      #
      # Provides access to all openHAB sitemap definitions, and acts like an array.
      #
      class Registry
        include LazyArray
        include Singleton

        #
        # Gets a specific sitemap definition.
        #
        # @param [String] name Sitemap name
        # @return [Sitemap, nil]
        #
        def [](name)
          # @deprecated OH 5.2: Remove the registry check when dropping OH 5.1
          Provider.registry ? Provider.registry.get(name) : Provider.current.get(name)
        end
        alias_method :include?, :[]
        alias_method :key?, :[]
        # @deprecated
        alias_method :has_key?, :[]

        #
        # Explicit conversion to array.
        #
        # @return [Array<Sitemap>]
        #
        def to_a
          # @deprecated OH 5.2: Remove the registry check when dropping OH 5.1
          Provider.registry ? Provider.registry.all.to_a : Provider.current.all.to_a
        end

        #
        # Enter the Sitemap Builder DSL.
        #
        # @param update [true, false]  When true, existing sitemaps with the same name will be updated.
        # @yield Block executed in the context of a {DSL::Sitemaps::Builder}
        # @return [void]
        #
        # @see DSL::Sitemaps::Builder
        #
        # @example
        #   sitemaps.build do
        #     sitemap "default", label: "My Residence" do
        #       frame label: "Control" do
        #         text label: "Climate", icon: "if:mdi:home-thermometer-outline" do
        #           frame label: "Main Floor" do
        #             # colors are set with a hash, with key being condition, and value being the color
        #             # The :default key is used when no other condition matches
        #             text item: MainFloor_AmbTemp,
        #               label_color: "purple", # A simple string can be used when no conditions are needed
        #               value_color: { ">=90" => "red", "<=70" => "blue", :default => "black" }
        #
        #             # If item name is not provided in the condition, it will default to the widget's Item
        #             # The operator will default to == if not specified
        #             switch item: MainFloorThermostat_TargetMode, label: "Mode",
        #               mappings: %w[off auto cool heat],
        #               value_color: { "cool" => "blue", "heat" => "red", :default => "black" }
        #
        #             # an array of conditions are AND'd together
        #             setpoint item: MainFloorThermostat_SetPoint, label: "Set Point",
        #               value_color: {
        #                 ["MainFloorThermostat_TargetMode!=off", ">80"] => "red", # red if mode!=off AND setpoint > 80
        #                 ["MainFloorThermostat_TargetMode!=off", ">74"] => "yellow",
        #                 ["MainFloorThermostat_TargetMode!=off", ">70"] => "green",
        #                 "MainFloorThermostat_TargetMode!=off" => "blue",
        #                 :default => "gray"
        #               }
        #           end
        #           frame label: "Basement" do
        #             text item: Basement_AmbTemp
        #             switch item: BasementThermostat_TargetMode, label: "Mode",
        #               mappings: { OFF: "off", COOL: "cool", HEAT: "heat" }
        #
        #             # Conditions within a nested array are AND'd together (requires openHAB 4.1)
        #             setpoint item: BasementThermostat_SetPoint, label: "Set Point",
        #               visibility: [["BasementThermostat_TargetMode!=off", "Vacation_Switch==OFF"]]
        #
        #             # Additional elements are OR'd
        #             # The following visibility conditions are evaluated as:
        #             # (BasementThermostat_TargetMode!=off AND Vacation_Switch==OFF) OR Verbose_Mode==ON
        #             setpoint item: BasementThermostat_SetPoint, label: "Set Point",
        #               visibility: [
        #                 ["BasementThermostat_TargetMode!=off", "Vacation_Switch==OFF"],
        #                 "Verbose_Mode==ON"
        #               ]
        #           end
        #         end
        #       end
        #     end
        #   end
        #
        # @example
        #   def add_tv(builder, tv)
        #     builder.frame label: tv.location.label do
        #       builder.switch item: tv.points(Semantics::Switch), label: "Power"
        #     end
        #   end
        #
        #   sitemaps.build do |builder|
        #     builder.sitemap "tvs", label: "TVs" do
        #       items.equipments(Semantics::TV).each do |tv|
        #         add_tv(builder, tv)
        #       end
        #     end
        #   end
        #
        def build(update: true, &block)
          builder_proxy = SimpleDelegator.new(nil) if block.arity == 1
          builder = DSL::Sitemaps::Builder.new(builder_proxy, update:)
          if block.arity == 1
            builder_proxy.__setobj__(builder)
            DSL::ThreadLocal.thread_local(openhab_create_dummy_items: true) do
              yield builder_proxy
            end
          else
            builder.instance_eval(&block)
          end
        end

        #
        # Remove a sitemap.
        #
        # The sitemap must be managed by Ruby.
        #
        # @param [String, Sitemap] sitemap Sitemap or sitemap name
        # @return [Sitemap] The removed sitemap.
        # @raise [RuntimeError] if the sitemap cannot be removed.
        #
        def remove(sitemap)
          sitemap = sitemap.uid if sitemap.respond_to?(:uid)
          old_instance = Provider.current.remove(sitemap)
          old_instance ||= Provider.registry&.remove(sitemap)

          raise "Cannot remove sitemap #{sitemap}" unless old_instance

          old_instance
        end
      end
    end
  end
end
