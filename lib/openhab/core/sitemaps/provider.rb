# frozen_string_literal: true

require "singleton"

module OpenHAB
  module Core
    #
    # Contains sitemap related classes.
    #
    module Sitemaps
      #
      # Provides sitemaps created in Ruby to openHAB
      #
      class Provider < Core::Provider
        SUFFIX = ".sitemap"
        private_constant :SUFFIX

        class << self
          # @!visibility private
          def registry
            nil
          end
        end

        include org.openhab.core.model.sitemap.SitemapProvider

        # @!visibility private
        alias_method :getSitemap, :get # rubocop:disable Naming/MethodName

        # rubocop:disable Naming/MethodName

        # @!visibility private
        def getSitemapNames
          @elements.key_set
        end

        # @!visibility private
        def addModelChangeListener(listener)
          @listeners.add(listener)
        end

        # @!visibility private
        def removeModelChangeListener(listener)
          @listeners.remove(listener)
        end

        # rubocop:enable Naming/MethodName

        # @!visibility private
        # Override this because we don't have a registry
        def unregister
          clear
          @registration.unregister
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
          builder = DSL::Sitemaps::Builder.new(self, builder_proxy, update:)
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
        # Notify listeners about updated sitemap
        #
        # @param [String, org.openhab.core.model.sitemap.sitemap.Sitemap] sitemap The sitemap to update.
        # @return [void]
        #
        def update(sitemap)
          if sitemap.respond_to?(:to_str)
            sitemap = get(sitemap).tap do |obj|
              raise ArgumentError, "Sitemap #{sitemap} not found" unless obj
            end
          end
          super
        end

        #
        # Remove a sitemap.
        #
        # @param [String, org.openhab.core.model.sitemap.sitemap.Sitemap] sitemap
        # @return [Boolean] If a sitemap was removed
        #
        def remove(sitemap)
          sitemap = sitemap.uid if sitemap.respond_to?(:uid)
          super
        end

        private

        def initialize
          super
          @listeners = java.util.concurrent.CopyOnWriteArraySet.new

          @registration = OSGi.register_service(self, org.openhab.core.model.sitemap.SitemapProvider)
        end

        def notify_listeners_about_added_element(element)
          model_name = "#{element.name}#{SUFFIX}"
          @listeners.each do |l|
            l.modelChanged(model_name, org.openhab.core.model.core.EventType::ADDED)
            # Ensure that when a script is reloaded, the sitemap is updated.
            # This is because our listener, org.openhab.core.io.rest.sitemap.SitemapSubscriptionService
            # only handles MODIFIED events in its modelChanged() method.
            l.modelChanged(model_name, org.openhab.core.model.core.EventType::MODIFIED)
          end
        end

        def notify_listeners_about_removed_element(element)
          model_name = "#{element.name}#{SUFFIX}"
          @listeners.each { |l| l.modelChanged(model_name, org.openhab.core.model.core.EventType::REMOVED) }
        end

        def notify_listeners_about_updated_element(_old_element, element)
          model_name = "#{element.name}#{SUFFIX}"
          @listeners.each { |l| l.modelChanged(model_name, org.openhab.core.model.core.EventType::MODIFIED) }
        end
      end
    end
  end
end
