# frozen_string_literal: true

module OpenHAB
  module DSL
    module UI
      module Components
        # System Widget Library.
        #
        # @see https://www.openhab.org/docs/ui/components/
        #
        module System
          # Add a `oh-button` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-button.html
          #
          # @param text [String, nil] Text
          # @param round [true, false, String, nil] Round. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param large [true, false, String, nil] Large. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param small [true, false, String, nil] Small. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param fill [true, false, String, nil] Fill. A `String` is a MainUI expression that evaluates to a boolean.
          # @param raised [true, false, String, nil] Raised. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param active [String, nil] Active
          # @param icon [Hash, nil] Icon options. Use a hash for detailed options.
          # @option icon [String, nil] f7 Icon
          # @option icon [String, nil] material Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [Integer, String, nil] size Icon Size
          # @param tooltip [String, Hash, nil] Tooltip. Use a hash for detailed options.
          # @option tooltip [String, nil] value Tooltip
          # @param variable [String, Hash, nil] Variable. Use a hash for detailed options.
          # @option variable [String, nil] value Variable
          # @option variable [String, nil] key Variable Key
          # @param clear_variable [true, false, String, Hash, nil] Clear Variable After Action. Use a hash for detailed
          #   options. A `String` is a MainUI expression that evaluates to a boolean.
          # @option clear_variable [true, false, String, nil] value Clear Variable After Action. A `String` is a MainUI
          #   expression that evaluates to a boolean.
          # @option clear_variable [true, false, String, nil] key Clear Object Variable Property After Action. A
          #   `String` is a MainUI expression that evaluates to a boolean.
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
          # @param taphold_action [String, Hash, nil] Action. Use a hash for detailed options.
          # @option taphold_action [String, nil] value Action
          # @option taphold_action [String, nil] url Action URL
          # @option taphold_action [true, false, String, nil] url_same_window Open in same tab/window. A `String` is a
          #   MainUI expression that evaluates to a boolean.
          # @option taphold_action [String, nil] http_method HTTP Method
          # @option taphold_action [String, nil] http_body HTTP Body
          # @option taphold_action [String, Core::Items::Item, nil] item Action Item
          # @option taphold_action [String, nil] command Action Command
          # @option taphold_action [String, nil] command_alt Action Toggle Command
          # @option taphold_action [String, nil] options Command Options
          # @option taphold_action [String, nil] rule Scene, Script or Rule
          # @option taphold_action [String, nil] rule_context Context
          # @option taphold_action [String, nil] page Page
          # @option taphold_action [String, nil] page_transition Transition Effect
          # @option taphold_action [String, nil] modal Modal Page or Widget
          # @option taphold_action [String, nil] modal_config Modal component configuration
          # @option taphold_action [String, nil] photos Images to show
          # @option taphold_action [String, nil] photo_browser_config Photo browser configuration
          # @option taphold_action [String, Core::Items::Item, nil] group_popup_item Group Popup Item
          # @option taphold_action [String, Core::Items::Item, nil] analyzer_items Item(s) to Analyze
          # @option taphold_action [String, nil] analyzer_chart_type Chart Type
          # @option taphold_action [String, nil] analyzer_coord_system Initial Coordinate System
          # @option taphold_action [String, nil] analyzer_aggregation Initial Aggregation
          # @option taphold_action [String, nil] confirmation Action Confirmation
          # @option taphold_action [String, nil] feedback Action Feedback
          # @option taphold_action [String, nil] variable Variable
          # @option taphold_action [String, nil] variable_value Variable Value
          # @option taphold_action [String, nil] variable_key Variable Key
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def button(text: nil,
                     round: nil,
                     large: nil,
                     small: nil,
                     fill: nil,
                     raised: nil,
                     outline: nil,
                     active: nil,
                     icon: nil,
                     tooltip: nil,
                     variable: nil,
                     clear_variable: nil,
                     action: nil,
                     taphold_action: nil,
                     config: {},
                     &)
            configuration = component_config(
              config,
              {
                "text" => text,
                "round" => round,
                "large" => large,
                "small" => small,
                "fill" => fill,
                "raised" => raised,
                "outline" => outline,
                "active" => active,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    f7: "iconF7",
                    material: "iconMaterial",
                    color: "iconColor",
                    size: "iconSize"
                  }
                ),
                **grouped_config(
                  :tooltip,
                  tooltip,
                  {
                    value: "tooltip"
                  }
                ),
                **grouped_config(
                  :variable,
                  variable,
                  {
                    value: "variable",
                    key: "variableKey"
                  }
                ),
                **grouped_config(
                  :clear_variable,
                  clear_variable,
                  {
                    value: "clearVariable",
                    key: "clearVariableKey"
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
                ),
                **grouped_config(
                  :taphold_action,
                  taphold_action,
                  {
                    value: "taphold_action",
                    url: "taphold_actionUrl",
                    url_same_window: "taphold_actionUrlSameWindow",
                    http_method: "taphold_actionHttpMethod",
                    http_body: "taphold_actionHttpBody",
                    item: "taphold_actionItem",
                    command: "taphold_actionCommand",
                    command_alt: "taphold_actionCommandAlt",
                    options: "taphold_actionOptions",
                    rule: "taphold_actionRule",
                    rule_context: "taphold_actionRuleContext",
                    page: "taphold_actionPage",
                    page_transition: "taphold_actionPageTransition",
                    modal: "taphold_actionModal",
                    modal_config: "taphold_actionModalConfig",
                    photos: "taphold_actionPhotos",
                    photo_browser_config: "taphold_actionPhotoBrowserConfig",
                    group_popup_item: "taphold_actionGroupPopupItem",
                    analyzer_items: "taphold_actionAnalyzerItems",
                    analyzer_chart_type: "taphold_actionAnalyzerChartType",
                    analyzer_coord_system: "taphold_actionAnalyzerCoordSystem",
                    analyzer_aggregation: "taphold_actionAnalyzerAggregation",
                    confirmation: "taphold_actionConfirmation",
                    feedback: "taphold_actionFeedback",
                    variable: "taphold_actionVariable",
                    variable_value: "taphold_actionVariableValue",
                    variable_key: "taphold_actionVariableKey"
                  }
                )
              }
            )
            helper_component("oh-button", config: configuration, &)
          end

          # Add a `oh-chart` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-chart.html
          #
          # @param chart_type [String, nil] Chart Type
          # @param period [String, nil] Initial Period
          # @param future [Numeric, String, nil] Future Proportion
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {DSL::Pages::ChartPageBuilder ChartPageBuilder}. With an explicit block argument, or when an enclosing
          #   block supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [DSL::Pages::ChartPageBuilder] The component builder
          # @return [DSL::Pages::ChartPageBuilder]
          def chart(chart_type: nil,
                    period: nil,
                    future: nil,
                    config: {},
                    &)
            configuration = component_config(
              config,
              {
                "chartType" => chart_type,
                "period" => period,
                "future" => future
              }
            )
            add_component(DSL::Pages::ChartPageBuilder, "oh-chart", config: configuration, &)
          end

          # Add a `oh-clock` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-clock.html
          #
          # @param format [String, nil] Date Format
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def clock(format: nil,
                    config: {},
                    &)
            configuration = component_config(
              config,
              {
                "format" => format
              }
            )
            helper_component("oh-clock", config: configuration, &)
          end

          # Add a `oh-colorpicker` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-colorpicker.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param modules [String, nil] Modules
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def colorpicker(item: nil,
                          modules: nil,
                          config: {},
                          &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "modules" => modules
              }
            )
            helper_component("oh-colorpicker", config: configuration, &)
          end

          # Add a `oh-context` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-context.html
          #
          # @param functions [String, nil] Widget Functions
          # @param constants [String, nil] Widget Constants
          # @param variables [String, nil] Widget Variables
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def context(functions: nil,
                      constants: nil,
                      variables: nil,
                      config: {},
                      &)
            configuration = component_config(
              config,
              {
                "functions" => functions,
                "constants" => constants,
                "variables" => variables
              }
            )
            helper_component("oh-context", config: configuration, &)
          end

          # Add a `oh-gauge` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-gauge.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param min [Integer, String, nil] Min
          # @param max [Integer, String, nil] Max
          # @param type [String, nil] Type
          # @param value [String, Hash, nil] Value. Use a hash for detailed options.
          # @option value [String, nil] value Value
          # @option value [String, nil] text Value Text
          # @option value [String, nil] text_color Value Text Color
          # @option value [String, nil] font_size Value Font Size
          # @option value [String, nil] font_weight Value Font Weight
          # @param size [Integer, String, nil] Size
          # @param bg_color [String, nil] Background Color
          # @param border [Hash, nil] Border options. Use a hash for detailed options.
          # @option border [String, nil] bg_color Border Background Color
          # @option border [String, nil] color Border Color
          # @option border [String, nil] width Border Width
          # @param label [Hash, nil] Label options. Use a hash for detailed options.
          # @option label [String, nil] text Label Text
          # @option label [String, nil] text_color Label Text Color
          # @option label [String, nil] font_size Label Font Size
          # @option label [String, nil] font_weight Label Font Weight
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def gauge(item: nil,
                    min: nil,
                    max: nil,
                    type: nil,
                    value: nil,
                    size: nil,
                    bg_color: nil,
                    border: nil,
                    label: nil,
                    config: {},
                    &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "min" => min,
                "max" => max,
                "type" => type,
                **grouped_config(
                  :value,
                  value,
                  {
                    value: "value",
                    text: "valueText",
                    text_color: "valueTextColor",
                    font_size: "valueFontSize",
                    font_weight: "valueFontWeight"
                  }
                ),
                "size" => size,
                "bgColor" => bg_color,
                **grouped_config(
                  :border,
                  border,
                  {
                    bg_color: "borderBgColor",
                    color: "borderColor",
                    width: "borderWidth"
                  }
                ),
                **grouped_config(
                  :label,
                  label,
                  {
                    text: "labelText",
                    text_color: "labelTextColor",
                    font_size: "labelFontSize",
                    font_weight: "labelFontWeight"
                  }
                )
              }
            )
            helper_component("oh-gauge", config: configuration, &)
          end

          # Add a `oh-icon` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-icon.html
          #
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @param width [String, Core::Items::Item, nil] Width
          # @param height [String, Core::Items::Item, nil] Height
          # @param color [String, nil] Color
          # @param inline [true, false, String, nil] Inline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param rotate [String, nil] Rotate
          # @param horizontal_flip [true, false, String, nil] Horizontal Flip. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param vertical_flip [true, false, String, nil] Vertical Flip. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param state [true, false, String, nil] State. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          def icon(icon: nil,
                   width: nil,
                   height: nil,
                   color: nil,
                   inline: nil,
                   rotate: nil,
                   horizontal_flip: nil,
                   vertical_flip: nil,
                   state: nil,
                   action: nil,
                   config: {},
                   &)
            configuration = component_config(
              config,
              {
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon"
                  }
                ),
                "width" => width,
                "height" => height,
                "color" => color,
                "inline" => inline,
                "rotate" => rotate,
                "horizontalFlip" => horizontal_flip,
                "verticalFlip" => vertical_flip,
                "state" => state,
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
            helper_component("oh-icon", config: configuration, &)
          end

          # Add a `oh-image` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-image.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param url [String, nil] URL
          # @param lazy [true, false, String, Hash, nil] Lazy Load. Use a hash for detailed options. A `String` is a
          #   MainUI expression that evaluates to a boolean.
          # @option lazy [true, false, String, nil] value Lazy Load. A `String` is a MainUI expression that evaluates to
          #   a boolean.
          # @option lazy [true, false, String, nil] fade_in Lazy Load Fade-in. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param refresh_interval [Integer, String, nil] Refresh Interval
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
          def image(item: nil,
                    url: nil,
                    lazy: nil,
                    refresh_interval: nil,
                    action: nil,
                    config: {},
                    &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "url" => url,
                **grouped_config(
                  :lazy,
                  lazy,
                  {
                    value: "lazy",
                    fade_in: "lazyFadeIn"
                  }
                ),
                "refreshInterval" => refresh_interval,
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
            helper_component("oh-image", config: configuration, &)
          end

          # Add a `oh-input` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-input.html
          #
          # @param name [String, nil] Name
          # @param type [String, nil] Input Type
          # @param inputmode [String, nil] Input Mode
          # @param placeholder [String, nil] Placeholder
          # @param send_button [true, false, String, nil] Send button. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @param clear_button [true, false, String, nil] Clear button. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param required [true, false, String, nil] Required. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param validate [true, false, String, Hash, nil] Validate. Use a hash for detailed options. A `String` is a
          #   MainUI expression that evaluates to a boolean.
          # @option validate [true, false, String, nil] value Validate. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @option validate [true, false, String, nil] on_blur Validate on blur (`validate-on-blur`). A `String` is a
          #   MainUI expression that evaluates to a boolean.
          # @param item [String, Core::Items::Item, nil] Item
          # @param use_display_state [true, false, String, nil] Use Display State. A `String` is a MainUI expression
          #   that evaluates to a boolean.
          # @param min [Numeric, String, nil] Minimum
          # @param max [Numeric, String, nil] Maximum
          # @param step [Numeric, String, nil] Step
          # @param show_time [true, false, String, nil] Show time. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param default_value [String, nil] Default value
          # @param variable [String, Hash, nil] Variable. Use a hash for detailed options.
          # @option variable [String, nil] value Variable
          # @option variable [String, nil] key Variable Key
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def input(name: nil,
                    type: nil,
                    inputmode: nil,
                    placeholder: nil,
                    send_button: nil,
                    clear_button: nil,
                    outline: nil,
                    required: nil,
                    validate: nil,
                    item: nil,
                    use_display_state: nil,
                    min: nil,
                    max: nil,
                    step: nil,
                    show_time: nil,
                    default_value: nil,
                    variable: nil,
                    config: {},
                    &)
            configuration = component_config(
              config,
              {
                "name" => name,
                "type" => type,
                "inputmode" => inputmode,
                "placeholder" => placeholder,
                "sendButton" => send_button,
                "clearButton" => clear_button,
                "outline" => outline,
                "required" => required,
                **grouped_config(
                  :validate,
                  validate,
                  {
                    value: "validate",
                    on_blur: "validate-on-blur"
                  }
                ),
                "item" => item,
                "useDisplayState" => use_display_state,
                "min" => min,
                "max" => max,
                "step" => step,
                "showTime" => show_time,
                "defaultValue" => default_value,
                **grouped_config(
                  :variable,
                  variable,
                  {
                    value: "variable",
                    key: "variableKey"
                  }
                )
              }
            )
            helper_component("oh-input", config: configuration, &)
          end

          # Add a `oh-knob` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-knob.html
          #
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
          # @param variable [String, Hash, nil] Variable. Use a hash for detailed options.
          # @option variable [String, nil] value Variable
          # @option variable [String, nil] key Variable Key
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def knob(item: nil,
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
                   variable: nil,
                   config: {},
                   &)
            configuration = component_config(
              config,
              {
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
                  :variable,
                  variable,
                  {
                    value: "variable",
                    key: "variableKey"
                  }
                )
              }
            )
            helper_component("oh-knob", config: configuration, &)
          end

          # Add a `oh-link` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-link.html
          #
          # @param text [String, nil] Text
          # @param icon [Hash, nil] Icon options. Use a hash for detailed options.
          # @option icon [String, nil] f7 Icon
          # @option icon [String, nil] material Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [Integer, String, nil] size Icon Size
          # @param badge [String, Hash, nil] Badge. Use a hash for detailed options.
          # @option badge [String, nil] value Badge
          # @option badge [String, nil] color Badge color
          # @param tooltip [String, Hash, nil] Tooltip. Use a hash for detailed options.
          # @option tooltip [String, nil] value Tooltip
          # @param variable [String, Hash, nil] Variable. Use a hash for detailed options.
          # @option variable [String, nil] value Variable
          # @option variable [String, nil] key Variable Key
          # @param clear_variable [true, false, String, Hash, nil] Clear Variable After Action. Use a hash for detailed
          #   options. A `String` is a MainUI expression that evaluates to a boolean.
          # @option clear_variable [true, false, String, nil] value Clear Variable After Action. A `String` is a MainUI
          #   expression that evaluates to a boolean.
          # @option clear_variable [true, false, String, nil] key Clear Object Variable Property After Action. A
          #   `String` is a MainUI expression that evaluates to a boolean.
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
          def link(text: nil,
                   icon: nil,
                   badge: nil,
                   tooltip: nil,
                   variable: nil,
                   clear_variable: nil,
                   action: nil,
                   config: {},
                   &)
            configuration = component_config(
              config,
              {
                "text" => text,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    f7: "iconF7",
                    material: "iconMaterial",
                    color: "iconColor",
                    size: "iconSize"
                  }
                ),
                **grouped_config(
                  :badge,
                  badge,
                  {
                    value: "badge",
                    color: "badgeColor"
                  }
                ),
                **grouped_config(
                  :tooltip,
                  tooltip,
                  {
                    value: "tooltip"
                  }
                ),
                **grouped_config(
                  :variable,
                  variable,
                  {
                    value: "variable",
                    key: "variableKey"
                  }
                ),
                **grouped_config(
                  :clear_variable,
                  clear_variable,
                  {
                    value: "clearVariable",
                    key: "clearVariableKey"
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
            helper_component("oh-link", config: configuration, &)
          end

          # Add a `oh-list` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-list.html
          #
          # @param simple_list [true, false, String, nil] Simple List. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @param media_list [true, false, String, nil] Media List. A `String` is a MainUI expression that evaluates to
          #   a boolean.
          # @param accordion_list [true, false, String, nil] Accordion List. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def list(simple_list: nil,
                   media_list: nil,
                   accordion_list: nil,
                   config: {},
                   &)
            configuration = component_config(
              config,
              {
                "simpleList" => simple_list,
                "mediaList" => media_list,
                "accordionList" => accordion_list
              }
            )
            helper_component("oh-list", config: configuration, &)
          end

          # Add a `oh-player` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-player.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param show_rewind_f_fward [true, false, String, nil] Rewind/Fast Forward. A `String` is a MainUI expression
          #   that evaluates to a boolean.
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def player(item: nil,
                     show_rewind_f_fward: nil,
                     config: {},
                     &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "showRewindFFward" => show_rewind_f_fward
              }
            )
            helper_component("oh-player", config: configuration, &)
          end

          # Add a `oh-repeater` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-repeater.html
          #
          # @param for [String, nil] Current element variable
          # @param source_type [String, nil] Source type
          # @param in [String, nil] Source array
          # @param range [Hash, nil] Range options. Use a hash for detailed options.
          # @option range [Integer, String, nil] start Range Start
          # @option range [Integer, String, nil] stop Range Stop
          # @option range [Integer, String, nil] step Range Step
          # @param group_item [String, Core::Items::Item, nil] Group Item
          # @param item_tags [String, nil] Item Tags
          # @param rule_tags [String, nil] Rule Tags
          # @param item_options [String, nil] Item with Options
          # @param fetch_metadata [String, nil] Fetch Item Metadata Namespaces
          # @param filter [String, nil] Filter expression
          # @param map [String, nil] Map expression
          # @param list_container [true, false, String, nil] List container. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param container [Hash, nil] Container options. Use a hash for detailed options.
          # @option container [String, nil] classes Classes of the container
          # @option container [String, nil] style Styles of the container
          # @param fragment [true, false, String, nil] No container (fragment). A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param cache_source [true, false, String, nil] Suppress source refresh. A `String` is a MainUI expression
          #   that evaluates to a boolean.
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def repeater(for: nil,
                       source_type: nil,
                       in: nil,
                       range: nil,
                       group_item: nil,
                       item_tags: nil,
                       rule_tags: nil,
                       item_options: nil,
                       fetch_metadata: nil,
                       filter: nil,
                       map: nil,
                       list_container: nil,
                       container: nil,
                       fragment: nil,
                       cache_source: nil,
                       config: {},
                       &)
            configuration = component_config(
              config,
              {
                "for" => binding.local_variable_get(:for),
                "in" => binding.local_variable_get(:in),
                "sourceType" => source_type,
                **grouped_config(
                  :range,
                  range,
                  {
                    start: "rangeStart",
                    stop: "rangeStop",
                    step: "rangeStep"
                  }
                ),
                "groupItem" => group_item,
                "itemTags" => item_tags,
                "ruleTags" => rule_tags,
                "itemOptions" => item_options,
                "fetchMetadata" => fetch_metadata,
                "filter" => filter,
                "map" => map,
                "listContainer" => list_container,
                **grouped_config(
                  :container,
                  container,
                  {
                    classes: "containerClasses",
                    style: "containerStyle"
                  }
                ),
                "fragment" => fragment,
                "cacheSource" => cache_source
              }
            )
            helper_component("oh-repeater", config: configuration, &)
          end

          # Add a `oh-rollershutter` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-rollershutter.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param dir_icons_style [String, nil] Direction Icons Style
          # @param stop_icon_style [String, nil] Stop Icon Style
          # @param state_in_center [true, false, String, nil] State in Center. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def rollershutter(item: nil,
                            dir_icons_style: nil,
                            stop_icon_style: nil,
                            state_in_center: nil,
                            config: {},
                            &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "dirIconsStyle" => dir_icons_style,
                "stopIconStyle" => stop_icon_style,
                "stateInCenter" => state_in_center
              }
            )
            helper_component("oh-rollershutter", config: configuration, &)
          end

          # Add a `oh-sipclient` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-sipclient.html
          #
          # @param icon [Hash, nil] Icon options. Use a hash for detailed options.
          # @option icon [Integer, String, nil] size Icon Size
          # @param websocket_url [String, nil] Websocket URL
          # @param domain [String, nil] SIP Domain
          # @param username [String, nil] SIP Username
          # @param password [String, nil] SIP Password
          # @param authorization_user [String, nil] Authorization User
          # @param enable_tones [true, false, String, nil] Enable tones. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param phonebook [String, nil] Phonebook
          # @param dtmf_string [String, nil] DTMF String
          # @param hide_caller_id [true, false, String, nil] Hide caller id. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param enable_video [true, false, String, nil] Enable Video. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param enable_local_video [true, false, String, nil] Enable Local Video View. A `String` is a MainUI
          #   expression that evaluates to a boolean.
          # @param default_video_aspect_ratio [String, nil] Default Aspect Ratio
          # @param disable_register [true, false, String, nil] Disable REGISTER. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param auto_answer [String, nil] Auto Answer
          # @param auto_dial [String, nil] Auto Dial
          # @param sip_state_item [String, Core::Items::Item, nil] SIP State Item
          # @param enable_sip_debug [true, false, String, nil] Enable SIP Debug. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def sipclient(icon: nil,
                        websocket_url: nil,
                        domain: nil,
                        username: nil,
                        password: nil,
                        authorization_user: nil,
                        enable_tones: nil,
                        phonebook: nil,
                        dtmf_string: nil,
                        hide_caller_id: nil,
                        enable_video: nil,
                        enable_local_video: nil,
                        default_video_aspect_ratio: nil,
                        disable_register: nil,
                        auto_answer: nil,
                        auto_dial: nil,
                        sip_state_item: nil,
                        enable_sip_debug: nil,
                        config: {},
                        &)
            configuration = component_config(
              config,
              {
                **grouped_config(
                  :icon,
                  icon,
                  {
                    size: "iconSize"
                  }
                ),
                "websocketUrl" => websocket_url,
                "domain" => domain,
                "username" => username,
                "password" => password,
                "authorizationUser" => authorization_user,
                "enableTones" => enable_tones,
                "phonebook" => phonebook,
                "dtmfString" => dtmf_string,
                "hideCallerId" => hide_caller_id,
                "enableVideo" => enable_video,
                "enableLocalVideo" => enable_local_video,
                "defaultVideoAspectRatio" => default_video_aspect_ratio,
                "disableRegister" => disable_register,
                "autoAnswer" => auto_answer,
                "autoDial" => auto_dial,
                "sipStateItem" => sip_state_item,
                "enableSIPDebug" => enable_sip_debug
              }
            )
            helper_component("oh-sipclient", config: configuration, &)
          end

          # Add a `oh-slider` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-slider.html
          #
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
          # @param variable [String, Hash, nil] Variable. Use a hash for detailed options.
          # @option variable [String, nil] value Variable
          # @option variable [String, nil] key Variable Key
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def slider(item: nil,
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
                     variable: nil,
                     config: {},
                     &)
            configuration = component_config(
              config,
              {
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
                  :variable,
                  variable,
                  {
                    value: "variable",
                    key: "variableKey"
                  }
                )
              }
            )
            helper_component("oh-slider", config: configuration, &)
          end

          # Add a `oh-stepper` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-stepper.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param min [Numeric, String, nil] Min
          # @param max [Numeric, String, nil] Max
          # @param step [Numeric, String, nil] Step
          # @param offset [Numeric, String, nil] Offset
          # @param buttons_only [true, false, String, nil] Buttons Only. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param enable_input [true, false, String, nil] Enable Input Field. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param small [true, false, String, nil] Small. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param large [true, false, String, nil] Large. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param fill [true, false, String, nil] Fill. A `String` is a MainUI expression that evaluates to a boolean.
          # @param raised [true, false, String, nil] Raised. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param round [true, false, String, nil] Round. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param autorepeat [true, false, String, Hash, nil] Auto-repeat. Use a hash for detailed options. A `String`
          #   is a MainUI expression that evaluates to a boolean.
          # @option autorepeat [true, false, String, nil] value Auto-repeat. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @option autorepeat [true, false, String, nil] dynamic Dynamic Auto-repeat. A `String` is a MainUI expression
          #   that evaluates to a boolean.
          # @param variable [String, Hash, nil] Variable. Use a hash for detailed options.
          # @option variable [String, nil] value Variable
          # @option variable [String, nil] key Variable Key
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def stepper(item: nil,
                      min: nil,
                      max: nil,
                      step: nil,
                      offset: nil,
                      buttons_only: nil,
                      enable_input: nil,
                      small: nil,
                      large: nil,
                      fill: nil,
                      raised: nil,
                      round: nil,
                      autorepeat: nil,
                      variable: nil,
                      config: {},
                      &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "min" => min,
                "max" => max,
                "step" => step,
                "offset" => offset,
                "buttonsOnly" => buttons_only,
                "enableInput" => enable_input,
                "small" => small,
                "large" => large,
                "fill" => fill,
                "raised" => raised,
                "round" => round,
                **grouped_config(
                  :autorepeat,
                  autorepeat,
                  {
                    value: "autorepeat",
                    dynamic: "autorepeatDynamic"
                  }
                ),
                **grouped_config(
                  :variable,
                  variable,
                  {
                    value: "variable",
                    key: "variableKey"
                  }
                )
              }
            )
            helper_component("oh-stepper", config: configuration, &)
          end

          # Add a `oh-swiper` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-swiper.html
          #
          # @param pagination [true, false, String, nil] Pagination. A `String` is a MainUI expression that evaluates to
          #   a boolean.
          # @param navigation [true, false, String, nil] Navigation. A `String` is a MainUI expression that evaluates to
          #   a boolean.
          # @param scrollbar [true, false, String, nil] Scrollbar. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def swiper(pagination: nil,
                     navigation: nil,
                     scrollbar: nil,
                     config: {},
                     &)
            configuration = component_config(
              config,
              {
                "pagination" => pagination,
                "navigation" => navigation,
                "scrollbar" => scrollbar
              }
            )
            helper_component("oh-swiper", config: configuration, &)
          end

          # Add a `oh-toggle` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-toggle.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param color [String, nil] Color
          # @param variable [String, Hash, nil] Variable. Use a hash for detailed options.
          # @option variable [String, nil] value Variable
          # @option variable [String, nil] key Variable Key
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def toggle(item: nil,
                     color: nil,
                     variable: nil,
                     config: {},
                     &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "color" => color,
                **grouped_config(
                  :variable,
                  variable,
                  {
                    value: "variable",
                    key: "variableKey"
                  }
                )
              }
            )
            helper_component("oh-toggle", config: configuration, &)
          end

          # Add a `oh-trend` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-trend.html
          #
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
          def trend(trend: nil,
                    config: {},
                    &)
            configuration = component_config(
              config,
              {
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
            helper_component("oh-trend", config: configuration, &)
          end

          # Add a `oh-video` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-video.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param url [String, nil] URL
          # @param type [String, nil] Type
          # @param hide_controls [true, false, String, nil] Hide Controls. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param start_manually [true, false, String, nil] Start Manually. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param start_muted [true, false, String, nil] Start Muted. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @param poster [Hash, nil] Poster options. Use a hash for detailed options.
          # @option poster [String, Core::Items::Item, nil] item Poster Item
          # @option poster [String, nil] url Poster URL
          # @param player_type [String, nil] Player Type
          # @param stun_server [String, nil] Stun Server
          # @param candidates_timeout [Numeric, String, nil] ICE candidates timeout
          # @param send_audio [true, false, String, nil] Two Way Audio. A `String` is a MainUI expression that evaluates
          #   to a boolean.
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
          def video(item: nil,
                    url: nil,
                    type: nil,
                    hide_controls: nil,
                    start_manually: nil,
                    start_muted: nil,
                    poster: nil,
                    player_type: nil,
                    stun_server: nil,
                    candidates_timeout: nil,
                    send_audio: nil,
                    action: nil,
                    config: {},
                    &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "url" => url,
                "type" => type,
                "hideControls" => hide_controls,
                "startManually" => start_manually,
                "startMuted" => start_muted,
                **grouped_config(
                  :poster,
                  poster,
                  {
                    item: "posterItem",
                    url: "posterURL"
                  }
                ),
                "playerType" => player_type,
                "stunServer" => stun_server,
                "candidatesTimeout" => candidates_timeout,
                "sendAudio" => send_audio,
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
            helper_component("oh-video", config: configuration, &)
          end

          # Add a `oh-webframe` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-webframe.html
          #
          # @param src [String, nil] Source URL
          # @param height [Integer, String, nil] Height
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def webframe(src: nil,
                       height: nil,
                       config: {},
                       &)
            configuration = component_config(
              config,
              {
                "src" => src,
                "height" => height
              }
            )
            helper_component("oh-webframe", config: configuration, &)
          end
        end
      end
    end
  end
end
