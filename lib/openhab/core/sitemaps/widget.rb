# frozen_string_literal: true

module OpenHAB
  module Core
    module Sitemaps
      # @interface
      java_import org.openhab.core.sitemap.Widget

      # @since openHAB 5.2.0
      module Widget
        # @!attribute [r] item
        # @return [String]

        # @!attribute [r] label
        # @return [String, nil]

        # @!attribute [r] icon
        # @return [String, nil]

        # @!attribute [r] widget_type
        # @return [String]

        # @return [String]
        def to_s
          r = "#<OpenHAB::Core::Sitemaps::#{widget_type}"
          r += " #{label.inspect}" if label
          r += " item=#{item}" if item
          r += inspect_details.to_s
          "#{r}>"
        end
        alias_method :inspect, :to_s

        private

        def inspect_details; end
      end
    end
  end
end
