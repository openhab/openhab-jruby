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
        PREFIX = "jruby_"
        SUFFIX = ".sitemap"
        private_constant :PREFIX, :SUFFIX

        class << self
          # @!visibility private
          def registry
            nil
          end
        end

        include org.openhab.core.model.sitemap.SitemapProvider

        # @!visibility private
        alias_method :getSitemap, :get

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
        def unregister
          @registration.unregister
        end

        # rubocop:disable Layout/LineLength

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
        #     sitemap "default", "My Residence" do
        #       frame label: "Control" do
        #         text label: "Climate", icon: "if:mdi:home-thermometer-outline" do
        #           frame label: "Main Floor" do
        #             text item: MainFloor_AmbTemp
        #             # colors are set with a hash, with key being condition, and value being the color
        #             switch item: MainFloorThermostat_TargetMode, label: "Mode", mappings: %w[off auto cool heat], label_color: { "==heat" => "red", "" => "black" }
        #             # an array of conditions are OR'd together
        #             switch item: MainFloorThermostat_TargetMode, label: "Mode", mappings: %w[off auto cool heat], label_color: { ["==heat", "==cool"], => "green" }
        #             setpoint item: MainFloorThermostat_SetPoint, label: "Set Point", visibility: "MainFloorThermostat_TargetMode!=off"
        #           end
        #           frame label: "Basement" do
        #             text item: Basement_AmbTemp
        #             switch item: BasementThermostat_TargetMode, label: "Mode", mappings: { OFF: "off", COOL: "cool", HEAT: "heat" }
        #             # nested arrays are conditions that are AND'd together, instead of OR'd (requires openHAB 4.1)
        #             setpoint item: BasementThermostat_SetPoint, label: "Set Point", visibility: [["BasementThermostat_TargetMode!=off", "Vacation_Switch!=OFF"]]
        #           end
        #         end
        #       end
        #     end
        #   end
        #
        def build(update: true, &block)
          DSL::Sitemaps::Builder.new(self, update: update).instance_eval(&block)
        end
        # rubocop:enable Layout/LineLength

        # For use in specs
        # @!visibility private
        def clear
          elements = @elements
          @elements = java.util.concurrent.ConcurrentHashMap.new
          elements.each_value do |v|
            notify_listeners_about_removed_element(v)
          end
        end

        #
        # Remove a sitemap.
        #
        # @param [String] sitemap_name
        # @return [Boolean] If a sitemap was removed
        def remove(sitemap_name)
          super("#{PREFIX}#{sitemap_name}#{SUFFIX}")
        end

        private

        def initialize
          super
          @listeners = java.util.concurrent.CopyOnWriteArraySet.new

          @registration = OSGi.register_service(self, org.openhab.core.model.sitemap.SitemapProvider)
        end

        def notify_listeners_about_added_element(element)
          @listeners.each { |l| l.model_changed(element.name, org.openhab.core.model.core.EventType::ADDED) }
        end

        def notify_listeners_about_removed_element(element)
          @listeners.each { |l| l.model_changed(element.name, org.openhab.core.model.core.EventType::REMOVED) }
        end

        def notify_listeners_about_updated_element(_old_element, element)
          @listeners.each { |l| l.model_changed(element.name, org.openhab.core.model.core.EventType::MODIFIED) }
        end
      end
    end
  end
end
