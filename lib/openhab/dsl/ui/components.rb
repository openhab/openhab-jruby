# frozen_string_literal: true

require_relative "components/system"
require_relative "components/cards"
require_relative "components/list_items"
require_relative "components/cells"
require_relative "components/home"

module OpenHAB
  module DSL
    module UI
      # Component helpers grouped by the categories in the MainUI component reference. Specialized builder classes
      # include the common widget categories and their own specialized category. Generic
      # {UI::ComponentBuilder#component component} / {UI::ComponentBuilder#c c} calls are available in every context,
      # including for custom widgets and Framework7 components.
      module Components
        # @!visibility private
        def self.helper?(name)
          [System,
           Cards,
           ListItems,
           Cells,
           Home,
           DSL::Pages::LayoutPageBuilder,
           DSL::Pages::MapPageBuilder,
           DSL::Pages::PlanPageBuilder,
           DSL::Pages::ChartPageBuilder,
           DSL::Pages::TabsPageBuilder].any? do |category|
            category.method_defined?(name, false)
          end
        end
      end
    end
  end
end
