# frozen_string_literal: true

module OpenHAB
  module DSL
    module UI
      module Components
        # Standard Widget Library (Cells).
        #
        # @see https://www.openhab.org/docs/ui/components/
        #
        module Cells
          # Add a `oh-cell` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-cell.html
          #
          # @param header [String, nil] Header
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param footer [String, nil] Footer
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @param color [String, nil] Highlight Color
          # @param on [String, nil] "On" expression
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
          # @param trend [Hash, nil] Trend options. Use a hash for detailed options.
          # @option trend [String, Core::Items::Item, nil] item Trend Line Item
          # @option trend [String, nil] stroke_width Trend Stroke Width
          # @option trend [String, nil] width Trend Line Width
          # @option trend [String, nil] gradient Trend Line Gradient
          # @option trend [String, nil] gradient_direction Trend Line Gradient Direction
          # @option trend [Integer, String, nil] sampling Trend Line Sampling
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def cell(header: nil,
                   title: nil,
                   subtitle: nil,
                   footer: nil,
                   icon: nil,
                   color: nil,
                   on: nil,
                   action: nil,
                   trend: nil,
                   config: {},
                   &)
            configuration = component_config(
              config,
              {
                "header" => header,
                "title" => title,
                "subtitle" => subtitle,
                "footer" => footer,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon"
                  }
                ),
                "color" => color,
                "on" => on,
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
                ),
                **grouped_config(
                  :trend,
                  trend,
                  {
                    item: "trendItem",
                    stroke_width: "trendStrokeWidth",
                    width: "trendWidth",
                    gradient: "trendGradient",
                    gradient_direction: "trendGradientDirection",
                    sampling: "trendSampling"
                  }
                )
              }
            )
            helper_component("oh-cell", config: configuration, &)
          end

          # Add a `oh-colorpicker-cell` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-colorpicker-cell.html
          #
          # @param header [String, nil] Header
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param footer [String, nil] Footer
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @param color [String, nil] Highlight Color
          # @param on [String, nil] "On" expression
          # @param item [String, Core::Items::Item, nil] Item
          # @param modules [String, nil] Modules
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
          def colorpicker_cell(header: nil,
                               title: nil,
                               subtitle: nil,
                               footer: nil,
                               icon: nil,
                               color: nil,
                               on: nil,
                               item: nil,
                               modules: nil,
                               action: nil,
                               config: {},
                               &)
            configuration = component_config(
              config,
              {
                "header" => header,
                "title" => title,
                "subtitle" => subtitle,
                "footer" => footer,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon"
                  }
                ),
                "color" => color,
                "on" => on,
                "item" => item,
                "modules" => modules,
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
            helper_component("oh-colorpicker-cell", config: configuration, &)
          end

          # Add a `oh-knob-cell` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-knob-cell.html
          #
          # @param header [String, nil] Header
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param footer [String, nil] Footer
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @param color [String, nil] Highlight Color
          # @param on [String, nil] "On" expression
          # @param item [String, Core::Items::Item, nil] Item
          # @param min [Integer, String, nil] Min
          # @param max [Integer, String, nil] Max
          # @param step [Numeric, String, nil] Step
          # @param offset [Numeric, String, nil] Offset
          # @param ignore_display_state [true, false, String, nil] Ignore Display State. A `String` is a MainUI
          #   expression that evaluates to a boolean.
          # @param release_only [true, false, String, nil] Send command only on release. A `String` is a MainUI
          #   expression that evaluates to a boolean.
          # @param command_interval [Integer, String, nil] Command Interval
          # @param delay_state_display [Integer, String, nil] Delay State Display
          # @param disabled [true, false, String, nil] Disabled. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param size [Integer, String, nil] Size
          # @param responsive [true, false, String, nil] Responsive. A `String` is a MainUI expression that evaluates to
          #   a boolean.
          # @param stroke_width [Integer, String, nil] Stroke Width
          # @param start_angle [Integer, String, nil] Start Angle
          # @param end_angle [Integer, String, nil] End Angle
          # @param circle_shape [String, nil] Circle Shape
          # @param line_cap [String, nil] Line Cap
          # @param dotted_path [String, nil] Dotted Path
          # @param border [Hash, nil] Border options. Use a hash for detailed options.
          # @option border [Integer, String, nil] width Border Width
          # @option border [String, nil] color Border Color
          # @param handle [Hash, nil] Handle options. Use a hash for detailed options.
          # @option handle [String, nil] size Handle Size
          # @option handle [String, nil] shape Handle Shape
          # @param path_color [String, nil] Path Color
          # @param range_color [String, nil] Range Color
          # @param tooltip [Hash, nil] Tooltip options. Use a hash for detailed options.
          # @option tooltip [String, nil] color Tooltip Color
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
          def knob_cell(header: nil,
                        title: nil,
                        subtitle: nil,
                        footer: nil,
                        icon: nil,
                        color: nil,
                        on: nil,
                        item: nil,
                        min: nil,
                        max: nil,
                        step: nil,
                        offset: nil,
                        ignore_display_state: nil,
                        release_only: nil,
                        command_interval: nil,
                        delay_state_display: nil,
                        disabled: nil,
                        size: nil,
                        responsive: nil,
                        stroke_width: nil,
                        start_angle: nil,
                        end_angle: nil,
                        circle_shape: nil,
                        line_cap: nil,
                        dotted_path: nil,
                        border: nil,
                        handle: nil,
                        path_color: nil,
                        range_color: nil,
                        tooltip: nil,
                        action: nil,
                        config: {},
                        &)
            configuration = component_config(
              config,
              {
                "header" => header,
                "title" => title,
                "subtitle" => subtitle,
                "footer" => footer,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon"
                  }
                ),
                "color" => color,
                "on" => on,
                "item" => item,
                "min" => min,
                "max" => max,
                "step" => step,
                "offset" => offset,
                "ignoreDisplayState" => ignore_display_state,
                "releaseOnly" => release_only,
                "commandInterval" => command_interval,
                "delayStateDisplay" => delay_state_display,
                "disabled" => disabled,
                "size" => size,
                "responsive" => responsive,
                "strokeWidth" => stroke_width,
                "startAngle" => start_angle,
                "endAngle" => end_angle,
                "circleShape" => circle_shape,
                "lineCap" => line_cap,
                "dottedPath" => dotted_path,
                **grouped_config(
                  :border,
                  border,
                  {
                    width: "borderWidth",
                    color: "borderColor"
                  }
                ),
                **grouped_config(
                  :handle,
                  handle,
                  {
                    size: "handleSize",
                    shape: "handleShape"
                  }
                ),
                "pathColor" => path_color,
                "rangeColor" => range_color,
                **grouped_config(
                  :tooltip,
                  tooltip,
                  {
                    color: "tooltipColor"
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
            helper_component("oh-knob-cell", config: configuration, &)
          end

          # Add a `oh-label-cell` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-label-cell.html
          #
          # @param header [String, nil] Header
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param footer [String, nil] Footer
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @param color [String, nil] Highlight Color
          # @param on [String, nil] "On" expression
          # @param item [String, Core::Items::Item, nil] Item
          # @param label [String, nil] Label
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
          # @param trend [Hash, nil] Trend options. Use a hash for detailed options.
          # @option trend [String, Core::Items::Item, nil] item Trend Line Item
          # @option trend [String, nil] stroke_width Trend Stroke Width
          # @option trend [String, nil] width Trend Line Width
          # @option trend [String, nil] gradient Trend Line Gradient
          # @option trend [String, nil] gradient_direction Trend Line Gradient Direction
          # @option trend [Integer, String, nil] sampling Trend Line Sampling
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def label_cell(header: nil,
                         title: nil,
                         subtitle: nil,
                         footer: nil,
                         icon: nil,
                         color: nil,
                         on: nil,
                         item: nil,
                         label: nil,
                         action: nil,
                         trend: nil,
                         config: {},
                         &)
            configuration = component_config(
              config,
              {
                "header" => header,
                "title" => title,
                "subtitle" => subtitle,
                "footer" => footer,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon"
                  }
                ),
                "color" => color,
                "on" => on,
                "item" => item,
                "label" => label,
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
                ),
                **grouped_config(
                  :trend,
                  trend,
                  {
                    item: "trendItem",
                    stroke_width: "trendStrokeWidth",
                    width: "trendWidth",
                    gradient: "trendGradient",
                    gradient_direction: "trendGradientDirection",
                    sampling: "trendSampling"
                  }
                )
              }
            )
            helper_component("oh-label-cell", config: configuration, &)
          end

          # Add a `oh-rollershutter-cell` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-rollershutter-cell.html
          #
          # @param header [String, nil] Header
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param footer [String, nil] Footer
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @param color [String, nil] Highlight Color
          # @param on [String, nil] "On" expression
          # @param item [String, Core::Items::Item, nil] Item
          # @param dir_icons_style [String, nil] Direction Icons Style
          # @param stop_icon_style [String, nil] Stop Icon Style
          # @param state_in_center [true, false, String, nil] State in Center. A `String` is a MainUI expression that
          #   evaluates to a boolean.
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
          def rollershutter_cell(header: nil,
                                 title: nil,
                                 subtitle: nil,
                                 footer: nil,
                                 icon: nil,
                                 color: nil,
                                 on: nil,
                                 item: nil,
                                 dir_icons_style: nil,
                                 stop_icon_style: nil,
                                 state_in_center: nil,
                                 action: nil,
                                 config: {},
                                 &)
            configuration = component_config(
              config,
              {
                "header" => header,
                "title" => title,
                "subtitle" => subtitle,
                "footer" => footer,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon"
                  }
                ),
                "color" => color,
                "on" => on,
                "item" => item,
                "dirIconsStyle" => dir_icons_style,
                "stopIconStyle" => stop_icon_style,
                "stateInCenter" => state_in_center,
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
            helper_component("oh-rollershutter-cell", config: configuration, &)
          end

          # Add a `oh-slider-cell` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-slider-cell.html
          #
          # @param header [String, nil] Header
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param footer [String, nil] Footer
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @param color [String, nil] Highlight Color
          # @param on [String, nil] "On" expression
          # @param item [String, Core::Items::Item, nil] Item
          # @param min [Numeric, String, nil] Min
          # @param max [Numeric, String, nil] Max
          # @param step [Numeric, String, nil] Step
          # @param vertical [true, false, String, nil] Vertical. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param label [true, false, String, nil] Display Label. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param scale [true, false, String, Hash, nil] Display Scale. Use a hash for detailed options. A `String` is
          #   a MainUI expression that evaluates to a boolean.
          # @option scale [true, false, String, nil] value Display Scale. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @option scale [Integer, String, nil] steps Scale steps
          # @option scale [Integer, String, nil] sub_steps Scale sub-steps
          # @param unit [String, nil] Unit
          # @param ignore_display_state [true, false, String, nil] Ignore Display State. A `String` is a MainUI
          #   expression that evaluates to a boolean.
          # @param release_only [true, false, String, nil] Send command only on release. A `String` is a MainUI
          #   expression that evaluates to a boolean.
          # @param command_interval [Integer, String, nil] Command Interval
          # @param delay_state_display [Integer, String, nil] Delay State Display
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
          def slider_cell(header: nil,
                          title: nil,
                          subtitle: nil,
                          footer: nil,
                          icon: nil,
                          color: nil,
                          on: nil,
                          item: nil,
                          min: nil,
                          max: nil,
                          step: nil,
                          vertical: nil,
                          label: nil,
                          scale: nil,
                          unit: nil,
                          ignore_display_state: nil,
                          release_only: nil,
                          command_interval: nil,
                          delay_state_display: nil,
                          action: nil,
                          config: {},
                          &)
            configuration = component_config(
              config,
              {
                "header" => header,
                "title" => title,
                "subtitle" => subtitle,
                "footer" => footer,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon"
                  }
                ),
                "color" => color,
                "on" => on,
                "item" => item,
                "min" => min,
                "max" => max,
                "step" => step,
                "vertical" => vertical,
                "label" => label,
                **grouped_config(
                  :scale,
                  scale,
                  {
                    value: "scale",
                    steps: "scaleSteps",
                    sub_steps: "scaleSubSteps"
                  }
                ),
                "unit" => unit,
                "ignoreDisplayState" => ignore_display_state,
                "releaseOnly" => release_only,
                "commandInterval" => command_interval,
                "delayStateDisplay" => delay_state_display,
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
            helper_component("oh-slider-cell", config: configuration, &)
          end
        end
      end
    end
  end
end
