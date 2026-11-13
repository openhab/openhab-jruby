# frozen_string_literal: true

module OpenHAB
  module DSL
    module UI
      module Components
        # Standard Widget Library (Standalone Cards).
        #
        # @see https://www.openhab.org/docs/ui/components/
        #
        module Cards
          # Add a `oh-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
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
          def card(title: nil,
                   footer: nil,
                   no_border: nil,
                   no_shadow: nil,
                   outline: nil,
                   action: nil,
                   taphold_action: nil,
                   config: {},
                   &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
            helper_component("oh-card", config: configuration, &)
          end

          # Add a `oh-clock-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-clock-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param time [Hash, nil] Time options. Use a hash for detailed options.
          # @option time [String, nil] format Time Format
          # @option time [String, nil] font_size Time Font Size
          # @option time [String, nil] font_weight Time Font Weight
          # @param show_date [true, false, String, nil] Show the date. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @param date [Hash, nil] Date options. Use a hash for detailed options.
          # @option date [String, nil] format Date Format
          # @option date [String, nil] pos Date Position
          # @option date [String, nil] font_size Date Font Size
          # @option date [String, nil] font_weight Date Font Weight
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
          def clock_card(title: nil,
                         footer: nil,
                         no_border: nil,
                         no_shadow: nil,
                         outline: nil,
                         time: nil,
                         show_date: nil,
                         date: nil,
                         action: nil,
                         config: {},
                         &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                **grouped_config(
                  :time,
                  time,
                  {
                    format: "timeFormat",
                    font_size: "timeFontSize",
                    font_weight: "timeFontWeight"
                  }
                ),
                "showDate" => show_date,
                **grouped_config(
                  :date,
                  date,
                  {
                    format: "dateFormat",
                    pos: "datePos",
                    font_size: "dateFontSize",
                    font_weight: "dateFontWeight"
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
            helper_component("oh-clock-card", config: configuration, &)
          end

          # Add a `oh-colorpicker-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-colorpicker-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param item [String, Core::Items::Item, nil] Item
          # @param modules [String, nil] Modules
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def colorpicker_card(title: nil,
                               footer: nil,
                               no_border: nil,
                               no_shadow: nil,
                               outline: nil,
                               item: nil,
                               modules: nil,
                               config: {},
                               &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                "item" => item,
                "modules" => modules
              }
            )
            helper_component("oh-colorpicker-card", config: configuration, &)
          end

          # Add a `oh-gauge-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-gauge-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          def gauge_card(title: nil,
                         footer: nil,
                         no_border: nil,
                         no_shadow: nil,
                         outline: nil,
                         item: nil,
                         min: nil,
                         max: nil,
                         type: nil,
                         value: nil,
                         size: nil,
                         bg_color: nil,
                         border: nil,
                         label: nil,
                         action: nil,
                         config: {},
                         &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
            helper_component("oh-gauge-card", config: configuration, &)
          end

          # Add a `oh-image-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-image-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          def image_card(title: nil,
                         footer: nil,
                         no_border: nil,
                         no_shadow: nil,
                         outline: nil,
                         item: nil,
                         url: nil,
                         lazy: nil,
                         refresh_interval: nil,
                         action: nil,
                         config: {},
                         &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
            helper_component("oh-image-card", config: configuration, &)
          end

          # Add a `oh-input-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-input-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param name [String, nil] Name
          # @param type [String, nil] Input Type
          # @param inputmode [String, nil] Input Mode
          # @param placeholder [String, nil] Placeholder
          # @param send_button [true, false, String, nil] Send button. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @param clear_button [true, false, String, nil] Clear button. A `String` is a MainUI expression that
          #   evaluates to a boolean.
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
          def input_card(title: nil,
                         footer: nil,
                         no_border: nil,
                         no_shadow: nil,
                         outline: nil,
                         name: nil,
                         type: nil,
                         inputmode: nil,
                         placeholder: nil,
                         send_button: nil,
                         clear_button: nil,
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
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                "name" => name,
                "type" => type,
                "inputmode" => inputmode,
                "placeholder" => placeholder,
                "sendButton" => send_button,
                "clearButton" => clear_button,
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
            helper_component("oh-input-card", config: configuration, &)
          end

          # Add a `oh-knob-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-knob-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def knob_card(title: nil,
                        footer: nil,
                        no_border: nil,
                        no_shadow: nil,
                        outline: nil,
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
                        config: {},
                        &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
                )
              }
            )
            helper_component("oh-knob-card", config: configuration, &)
          end

          # Add a `oh-label-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-label-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
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
          # @param item [String, Core::Items::Item, nil] Item
          # @param label [String, nil] Label
          # @param background [String, nil] Background style
          # @param font [Hash, nil] Font options. Use a hash for detailed options.
          # @option font [String, nil] size Font Size
          # @option font [String, nil] weight Font Weight
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [Integer, String, nil] size Icon Size
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
          # @param vertical [true, false, String, nil] Vertical arrangement. A `String` is a MainUI expression that
          #   evaluates to a boolean.
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
          def label_card(title: nil,
                         footer: nil,
                         no_border: nil,
                         no_shadow: nil,
                         outline: nil,
                         action: nil,
                         taphold_action: nil,
                         item: nil,
                         label: nil,
                         background: nil,
                         font: nil,
                         icon: nil,
                         vertical: nil,
                         trend: nil,
                         config: {},
                         &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
                ),
                "item" => item,
                "label" => label,
                "background" => background,
                **grouped_config(
                  :font,
                  font,
                  {
                    size: "fontSize",
                    weight: "fontWeight"
                  }
                ),
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    size: "iconSize",
                    use_state: "iconUseState"
                  }
                ),
                "vertical" => vertical,
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
            helper_component("oh-label-card", config: configuration, &)
          end

          # Add a `oh-list-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-list-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          def list_card(title: nil,
                        footer: nil,
                        no_border: nil,
                        no_shadow: nil,
                        outline: nil,
                        simple_list: nil,
                        media_list: nil,
                        accordion_list: nil,
                        config: {},
                        &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                "simpleList" => simple_list,
                "mediaList" => media_list,
                "accordionList" => accordion_list
              }
            )
            helper_component("oh-list-card", config: configuration, &)
          end

          # Add a `oh-player-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-player-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param item [String, Core::Items::Item, nil] Item
          # @param show_rewind_f_fward [true, false, String, nil] Rewind/Fast Forward. A `String` is a MainUI expression
          #   that evaluates to a boolean.
          # @param artist_item [String, Core::Items::Item, nil] Artist Item
          # @param track_item [String, Core::Items::Item, nil] Track Item
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def player_card(title: nil,
                          footer: nil,
                          no_border: nil,
                          no_shadow: nil,
                          outline: nil,
                          item: nil,
                          show_rewind_f_fward: nil,
                          artist_item: nil,
                          track_item: nil,
                          config: {},
                          &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                "item" => item,
                "showRewindFFward" => show_rewind_f_fward,
                "artistItem" => artist_item,
                "trackItem" => track_item
              }
            )
            helper_component("oh-player-card", config: configuration, &)
          end

          # Add a `oh-rollershutter-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-rollershutter-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param vertical [true, false, String, nil] Vertical. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          def rollershutter_card(title: nil,
                                 footer: nil,
                                 no_border: nil,
                                 no_shadow: nil,
                                 outline: nil,
                                 vertical: nil,
                                 item: nil,
                                 dir_icons_style: nil,
                                 stop_icon_style: nil,
                                 state_in_center: nil,
                                 config: {},
                                 &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                "vertical" => vertical,
                "item" => item,
                "dirIconsStyle" => dir_icons_style,
                "stopIconStyle" => stop_icon_style,
                "stateInCenter" => state_in_center
              }
            )
            helper_component("oh-rollershutter-card", config: configuration, &)
          end

          # Add a `oh-sipclient-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-sipclient-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          def sipclient_card(title: nil,
                             footer: nil,
                             no_border: nil,
                             no_shadow: nil,
                             outline: nil,
                             icon: nil,
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
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
            helper_component("oh-sipclient-card", config: configuration, &)
          end

          # Add a `oh-slider-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-slider-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def slider_card(title: nil,
                          footer: nil,
                          no_border: nil,
                          no_shadow: nil,
                          outline: nil,
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
                          config: {},
                          &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
                "delayStateDisplay" => delay_state_display
              }
            )
            helper_component("oh-slider-card", config: configuration, &)
          end

          # Add a `oh-stepper-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-stepper-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def stepper_card(title: nil,
                           footer: nil,
                           no_border: nil,
                           no_shadow: nil,
                           outline: nil,
                           item: nil,
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
                           config: {},
                           &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
                )
              }
            )
            helper_component("oh-stepper-card", config: configuration, &)
          end

          # Add a `oh-swiper-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-swiper-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          def swiper_card(title: nil,
                          footer: nil,
                          no_border: nil,
                          no_shadow: nil,
                          outline: nil,
                          pagination: nil,
                          navigation: nil,
                          scrollbar: nil,
                          config: {},
                          &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                "pagination" => pagination,
                "navigation" => navigation,
                "scrollbar" => scrollbar
              }
            )
            helper_component("oh-swiper-card", config: configuration, &)
          end

          # Add a `oh-toggle-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-toggle-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param item [String, Core::Items::Item, nil] Item
          # @param color [String, nil] Color
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def toggle_card(title: nil,
                          footer: nil,
                          no_border: nil,
                          no_shadow: nil,
                          outline: nil,
                          item: nil,
                          color: nil,
                          config: {},
                          &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                "item" => item,
                "color" => color
              }
            )
            helper_component("oh-toggle-card", config: configuration, &)
          end

          # Add a `oh-video-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-video-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
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
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def video_card(title: nil,
                         footer: nil,
                         no_border: nil,
                         no_shadow: nil,
                         outline: nil,
                         item: nil,
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
                         config: {},
                         &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
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
                "sendAudio" => send_audio
              }
            )
            helper_component("oh-video-card", config: configuration, &)
          end

          # Add a `oh-webframe-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-webframe-card.html
          #
          # @param title [String, nil] Title
          # @param footer [String, nil] Footer text
          # @param no_border [true, false, String, nil] No Border. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param no_shadow [true, false, String, nil] No Shadow. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param outline [true, false, String, nil] Outline. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param borders [true, false, String, nil] Borders. A `String` is a MainUI expression that evaluates to a
          #   boolean.
          # @param src [String, nil] Source URL
          # @param height [Integer, String, nil] Height
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def webframe_card(title: nil,
                            footer: nil,
                            no_border: nil,
                            no_shadow: nil,
                            outline: nil,
                            borders: nil,
                            src: nil,
                            height: nil,
                            config: {},
                            &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "footer" => footer,
                "noBorder" => no_border,
                "noShadow" => no_shadow,
                "outline" => outline,
                "borders" => borders,
                "src" => src,
                "height" => height
              }
            )
            helper_component("oh-webframe-card", config: configuration, &)
          end
        end
      end
    end
  end
end
