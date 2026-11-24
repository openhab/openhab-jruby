# frozen_string_literal: true

module OpenHAB
  module DSL
    module UI
      module Components
        # Standard Widget Library (List Items).
        #
        # @see https://www.openhab.org/docs/ui/components/
        #
        module ListItems
          # Add a `oh-colorpicker-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-colorpicker-item.html
          #
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
          # @param item [String, Core::Items::Item, nil] Item
          # @param modules [String, nil] Modules
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def colorpicker_item(title: nil,
                               subtitle: nil,
                               after: nil,
                               icon: nil,
                               item: nil,
                               modules: nil,
                               config: {},
                               &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
                  }
                ),
                "item" => item,
                "modules" => modules
              }
            )
            helper_component("oh-colorpicker-item", config: configuration, &)
          end

          # Add a `oh-input-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-input-item.html
          #
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
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
          def input_item(title: nil,
                         subtitle: nil,
                         after: nil,
                         icon: nil,
                         name: nil,
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
                "title" => title,
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
                  }
                ),
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
            helper_component("oh-input-item", config: configuration, &)
          end

          # Add a `oh-label-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-label-item.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
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
          def label_item(item: nil,
                         title: nil,
                         subtitle: nil,
                         after: nil,
                         icon: nil,
                         action: nil,
                         config: {},
                         &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "title" => title,
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
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
            helper_component("oh-label-item", config: configuration, &)
          end

          # Add a `oh-list-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-list-item.html
          #
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
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
          # @param badge [String, Hash, nil] Badge. Use a hash for detailed options.
          # @option badge [String, nil] value Badge
          # @option badge [String, nil] color Badge color
          # @param list_button [true, false, String, Hash, nil] List Button. Use a hash for detailed options. A `String`
          #   is a MainUI expression that evaluates to a boolean.
          # @option list_button [true, false, String, nil] value List Button. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @option list_button [String, nil] color List Button Color
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def list_item(title: nil,
                        subtitle: nil,
                        after: nil,
                        icon: nil,
                        action: nil,
                        badge: nil,
                        list_button: nil,
                        config: {},
                        &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
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
                  :badge,
                  badge,
                  {
                    value: "badge",
                    color: "badgeColor"
                  }
                ),
                **grouped_config(
                  :list_button,
                  list_button,
                  {
                    value: "listButton",
                    color: "listButtonColor"
                  }
                )
              }
            )
            helper_component("oh-list-item", config: configuration, &)
          end

          # Add a `oh-player-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-player-item.html
          #
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
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
          def player_item(title: nil,
                          subtitle: nil,
                          after: nil,
                          icon: nil,
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
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
                  }
                ),
                "item" => item,
                "showRewindFFward" => show_rewind_f_fward,
                "artistItem" => artist_item,
                "trackItem" => track_item
              }
            )
            helper_component("oh-player-item", config: configuration, &)
          end

          # Add a `oh-rollershutter-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-rollershutter-item.html
          #
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
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
          def rollershutter_item(title: nil,
                                 subtitle: nil,
                                 after: nil,
                                 icon: nil,
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
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
                  }
                ),
                "vertical" => vertical,
                "item" => item,
                "dirIconsStyle" => dir_icons_style,
                "stopIconStyle" => stop_icon_style,
                "stateInCenter" => state_in_center
              }
            )
            helper_component("oh-rollershutter-item", config: configuration, &)
          end

          # Add a `oh-slider-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-slider-item.html
          #
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
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
          def slider_item(title: nil,
                          subtitle: nil,
                          after: nil,
                          icon: nil,
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
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
                  }
                ),
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
            helper_component("oh-slider-item", config: configuration, &)
          end

          # Add a `oh-stepper-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-stepper-item.html
          #
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
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
          def stepper_item(title: nil,
                           subtitle: nil,
                           after: nil,
                           icon: nil,
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
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
                  }
                ),
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
            helper_component("oh-stepper-item", config: configuration, &)
          end

          # Add a `oh-toggle-item` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-toggle-item.html
          #
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param after [String, nil] After
          # @param icon [String, Hash, nil] Icon. Use a hash for detailed options.
          # @option icon [String, nil] value Icon
          # @option icon [String, nil] color Icon Color
          # @option icon [true, false, String, nil] use_state Icon depends on state. A `String` is a MainUI expression
          #   that evaluates to a boolean.
          # @param item [String, Core::Items::Item, nil] Item
          # @param color [String, nil] Color
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def toggle_item(title: nil,
                          subtitle: nil,
                          after: nil,
                          icon: nil,
                          item: nil,
                          color: nil,
                          config: {},
                          &)
            configuration = component_config(
              config,
              {
                "title" => title,
                "subtitle" => subtitle,
                "after" => after,
                **grouped_config(
                  :icon,
                  icon,
                  {
                    value: "icon",
                    color: "iconColor",
                    use_state: "iconUseState"
                  }
                ),
                "item" => item,
                "color" => color
              }
            )
            helper_component("oh-toggle-item", config: configuration, &)
          end
        end
      end
    end
  end
end
