# frozen_string_literal: true

module OpenHAB
  module DSL
    module Pages
      # Floorplan Page & Markers.
      #
      # @see https://www.openhab.org/docs/ui/components/
      #
      class PlanPageBuilder < PageBuilder
        # Add a `oh-plan-marker` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-plan-marker.html
        #
        # @param name [String, nil] Name
        # @param coords [String, nil] Coordinates
        # @param item [String, Core::Items::Item, nil] Item
        # @param visible [String, nil] Visibility
        # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
        # @option icon [String, nil] value Icon
        # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @option icon [Integer, String, nil] size Icon Size
        # @option icon [Integer, String, nil] width Icon Width
        # @option icon [Integer, String, nil] height Icon Height
        # @option icon [String, nil] color Icon Color
        # @option icon [Integer, String, nil] rotation Icon Rotation
        # @param tooltip [String, Hash, nil] Tooltip Text. Use a hash for detailed options.
        # @option tooltip [String, nil] value Tooltip Text
        # @option tooltip [true, false, String, nil] permanent Always display the tooltip. A `String` is a MainUI
        #   expression that evaluates to a boolean.
        # @option tooltip [true, false, String, nil] as_label Use Tooltip as Label. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @option tooltip [String, nil] font_size Tooltip Font Size
        # @option tooltip [String, nil] color Tooltip color
        # @option tooltip [String, nil] direction Tooltip Direction
        # @option tooltip [Integer, String, nil] offset_x Tooltip Offset X
        # @option tooltip [Integer, String, nil] offset_y Tooltip Offset Y
        # @option tooltip [Numeric, String, nil] opacity Tooltip Opacity
        # @param zoom_visibility [Hash, nil] Zoom visibility options. Use a hash for detailed options.
        # @option zoom_visibility [Integer, String, nil] min Zoom Visibility Minimum
        # @option zoom_visibility [Integer, String, nil] max Zoom Visibility Maximum
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
        def plan_marker(name: nil,
                        coords: nil,
                        item: nil,
                        visible: nil,
                        icon: nil,
                        tooltip: nil,
                        zoom_visibility: nil,
                        action: nil,
                        config: {},
                        &)
          configuration = component_config(
            config,
            {
              "name" => name,
              "coords" => coords,
              "item" => item,
              "visible" => visible,
              **grouped_config(
                :icon,
                icon,
                {
                  value: "icon",
                  use_state: "iconUseState",
                  size: "iconSize",
                  width: "iconWidth",
                  height: "iconHeight",
                  color: "iconColor",
                  rotation: "iconRotation"
                }
              ),
              **grouped_config(
                :tooltip,
                tooltip,
                {
                  value: "tooltip",
                  permanent: "tooltipPermanent",
                  as_label: "useTooltipAsLabel",
                  font_size: "tooltipFontSize",
                  color: "tooltipColor",
                  direction: "tooltipDirection",
                  offset_x: "tooltipOffsetX",
                  offset_y: "tooltipOffsetY",
                  opacity: "tooltipOpacity"
                }
              ),
              **grouped_config(
                :zoom_visibility,
                zoom_visibility,
                {
                  min: "zoomVisibilityMin",
                  max: "zoomVisibilityMax"
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
          helper_component("oh-plan-marker", config: configuration, &)
        end
      end
    end
  end
end
