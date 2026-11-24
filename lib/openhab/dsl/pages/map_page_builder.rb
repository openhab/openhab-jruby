# frozen_string_literal: true

module OpenHAB
  module DSL
    module Pages
      # Map Page & Markers.
      #
      # @see https://www.openhab.org/docs/ui/components/
      #
      class MapPageBuilder < PageBuilder
        # Add a `oh-map-circle-marker` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-map-circle-marker.html
        #
        # @param label [String, nil] Label
        # @param color [String, nil] Circle color
        # @param item [String, Core::Items::Item, nil] Item
        # @param location [String, nil] Fixed location
        # @param radius [Numeric, String, Hash, nil] Fixed radius. Use a hash for detailed options.
        # @option radius [String, Core::Items::Item, nil] item Radius Item
        # @option radius [Numeric, String, nil] value Fixed radius
        # @param action [String, Hash, nil] Action. Use a hash for detailed options.
        # @option action [String, nil] value Action
        # @option action [String, nil] url Action URL
        # @option action [true, false, String, nil] url_same_window Open in same tab/window. A `String` is a MainUI
        #   expression that evaluates to a boolean.
        # @option action [String, nil] http_method HTTP Method
        # @option action [String, nil] http_body HTTP Body
        # @option action [String, Core::Items::Item, nil] item Action Item
        # @option action [String, nil] command Action Command
        # @option action [String, nil] command_alt Action Toggle Command
        # @option action [String, nil] options Command Options
        # @option action [String, nil] rule Scene, Script or Rule
        # @option action [String, nil] rule_context Context
        # @option action [String, nil] page Page
        # @option action [String, nil] page_transition Transition Effect
        # @option action [String, nil] modal Modal Page or Widget
        # @option action [String, nil] modal_config Modal component configuration
        # @option action [String, nil] photos Images to show
        # @option action [String, nil] photo_browser_config Photo browser configuration
        # @option action [String, Core::Items::Item, nil] group_popup_item Group Popup Item
        # @option action [String, Core::Items::Item, nil] analyzer_items Item(s) to Analyze
        # @option action [String, nil] analyzer_chart_type Chart Type
        # @option action [String, nil] analyzer_coord_system Initial Coordinate System
        # @option action [String, nil] analyzer_aggregation Initial Aggregation
        # @option action [String, nil] confirmation Action Confirmation
        # @option action [String, nil] feedback Action Feedback
        # @option action [String, nil] variable Variable
        # @option action [String, nil] variable_value Variable Value
        # @option action [String, nil] variable_key Variable Key
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def map_circle_marker(label: nil,
                              color: nil,
                              item: nil,
                              location: nil,
                              radius: nil,
                              action: nil,
                              config: {},
                              &)
          configuration = component_config(
            config,
            {
              "label" => label,
              "color" => color,
              "item" => item,
              "location" => location,
              **grouped_config(
                :radius,
                radius,
                {
                  item: "radiusItem",
                  value: "radius"
                }
              ),
              **grouped_config(
                :action,
                action,
                {
                  value: "action",
                  url: "actionUrl",
                  url_same_window: "actionUrlSameWindow",
                  http_method: "actionHttpMethod",
                  http_body: "actionHttpBody",
                  item: "actionItem",
                  command: "actionCommand",
                  command_alt: "actionCommandAlt",
                  options: "actionOptions",
                  rule: "actionRule",
                  rule_context: "actionRuleContext",
                  page: "actionPage",
                  page_transition: "actionPageTransition",
                  modal: "actionModal",
                  modal_config: "actionModalConfig",
                  photos: "actionPhotos",
                  photo_browser_config: "actionPhotoBrowserConfig",
                  group_popup_item: "actionGroupPopupItem",
                  analyzer_items: "actionAnalyzerItems",
                  analyzer_chart_type: "actionAnalyzerChartType",
                  analyzer_coord_system: "actionAnalyzerCoordSystem",
                  analyzer_aggregation: "actionAnalyzerAggregation",
                  confirmation: "actionConfirmation",
                  feedback: "actionFeedback",
                  variable: "actionVariable",
                  variable_value: "actionVariableValue",
                  variable_key: "actionVariableKey"
                }
              )
            }
          )
          helper_component("oh-map-circle-marker", config: configuration, &)
        end

        # Add a `oh-map-marker` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-map-marker.html
        #
        # @param label [String, nil] Label
        # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
        # @option icon [String, nil] value Icon
        # @param item [String, Core::Items::Item, nil] Item
        # @param location [String, nil] Fixed location
        # @param action [String, Hash, nil] Action. Use a hash for detailed options.
        # @option action [String, nil] value Action
        # @option action [String, nil] url Action URL
        # @option action [true, false, String, nil] url_same_window Open in same tab/window. A `String` is a MainUI
        #   expression that evaluates to a boolean.
        # @option action [String, nil] http_method HTTP Method
        # @option action [String, nil] http_body HTTP Body
        # @option action [String, Core::Items::Item, nil] item Action Item
        # @option action [String, nil] command Action Command
        # @option action [String, nil] command_alt Action Toggle Command
        # @option action [String, nil] options Command Options
        # @option action [String, nil] rule Scene, Script or Rule
        # @option action [String, nil] rule_context Context
        # @option action [String, nil] page Page
        # @option action [String, nil] page_transition Transition Effect
        # @option action [String, nil] modal Modal Page or Widget
        # @option action [String, nil] modal_config Modal component configuration
        # @option action [String, nil] photos Images to show
        # @option action [String, nil] photo_browser_config Photo browser configuration
        # @option action [String, Core::Items::Item, nil] group_popup_item Group Popup Item
        # @option action [String, Core::Items::Item, nil] analyzer_items Item(s) to Analyze
        # @option action [String, nil] analyzer_chart_type Chart Type
        # @option action [String, nil] analyzer_coord_system Initial Coordinate System
        # @option action [String, nil] analyzer_aggregation Initial Aggregation
        # @option action [String, nil] confirmation Action Confirmation
        # @option action [String, nil] feedback Action Feedback
        # @option action [String, nil] variable Variable
        # @option action [String, nil] variable_value Variable Value
        # @option action [String, nil] variable_key Variable Key
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def map_marker(label: nil,
                       icon: nil,
                       item: nil,
                       location: nil,
                       action: nil,
                       config: {},
                       &)
          configuration = component_config(
            config,
            {
              "label" => label,
              **grouped_config(
                :icon,
                icon,
                {
                  value: "icon"
                }
              ),
              "item" => item,
              "location" => location,
              **grouped_config(
                :action,
                action,
                {
                  value: "action",
                  url: "actionUrl",
                  url_same_window: "actionUrlSameWindow",
                  http_method: "actionHttpMethod",
                  http_body: "actionHttpBody",
                  item: "actionItem",
                  command: "actionCommand",
                  command_alt: "actionCommandAlt",
                  options: "actionOptions",
                  rule: "actionRule",
                  rule_context: "actionRuleContext",
                  page: "actionPage",
                  page_transition: "actionPageTransition",
                  modal: "actionModal",
                  modal_config: "actionModalConfig",
                  photos: "actionPhotos",
                  photo_browser_config: "actionPhotoBrowserConfig",
                  group_popup_item: "actionGroupPopupItem",
                  analyzer_items: "actionAnalyzerItems",
                  analyzer_chart_type: "actionAnalyzerChartType",
                  analyzer_coord_system: "actionAnalyzerCoordSystem",
                  analyzer_aggregation: "actionAnalyzerAggregation",
                  confirmation: "actionConfirmation",
                  feedback: "actionFeedback",
                  variable: "actionVariable",
                  variable_value: "actionVariableValue",
                  variable_key: "actionVariableKey"
                }
              )
            }
          )
          helper_component("oh-map-marker", config: configuration, &)
        end
      end
    end
  end
end
