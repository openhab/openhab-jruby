# frozen_string_literal: true

module OpenHAB
  module Core
    module Sitemaps
      # @interface
      java_import org.openhab.core.sitemap.LinkableWidget

      # @since openHAB 5.2.0
      module LinkableWidget
        # @!parse
        #   include Widget

        # @!attribute [r] widgets
        # @return [<Widget>]

        private

        def inspect_details
          children_count = widgets.size
          " (#{children_count} child#{"ren" if children_count != 1})" if children_count.positive?
        end
      end
    end
  end
end
