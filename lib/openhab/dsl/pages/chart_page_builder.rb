# frozen_string_literal: true

module OpenHAB
  module DSL
    module Pages
      # Chart Page & Components.
      #
      # @see https://www.openhab.org/docs/ui/components/
      #
      class ChartPageBuilder < PageBuilder
        # Add a `oh-chart-grid` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-chart-grid.html
        #
        # @param show [true, false, String, nil] Show. A `String` is a MainUI expression that evaluates to a boolean.
        # @param contain_label [true, false, String, nil] Contain label. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param top [String, nil] Top
        # @param bottom [String, nil] Bottom
        # @param left [String, nil] Left
        # @param right [String, nil] Right
        # @param width [String, nil] Width
        # @param height [String, nil] Height
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def chart_grid(show: nil,
                       contain_label: nil,
                       top: nil,
                       bottom: nil,
                       left: nil,
                       right: nil,
                       width: nil,
                       height: nil,
                       config: {},
                       &)
          configuration = component_config(
            config,
            {
              "show" => show,
              "containLabel" => contain_label,
              "top" => top,
              "bottom" => bottom,
              "left" => left,
              "right" => right,
              "width" => width,
              "height" => height
            }
          )
          helper_component("oh-chart-grid", config: configuration, &)
        end

        # Add a `oh-category-axis` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-category-axis.html
        #
        # @param name [String, Hash, nil] Name. Use a hash for detailed options.
        # @option name [String, nil] value Name
        # @option name [String, nil] location Name Location
        # @option name [Integer, String, nil] gap Name Gap
        # @option name [String, nil] rotate Name Rotate
        # @param category_type [String, nil] Categories
        # @param weekday_format [String, nil] Weekday Format
        # @param starton_sunday [true, false, String, nil] Start Week on Sunday. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param month_format [String, nil] Month Format
        # @param data [String, nil] Category Values
        # @param grid_index [Integer, String, nil] Grid Index
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def category_axis(name: nil,
                          category_type: nil,
                          weekday_format: nil,
                          starton_sunday: nil,
                          month_format: nil,
                          data: nil,
                          grid_index: nil,
                          config: {},
                          &)
          configuration = component_config(
            config,
            {
              **grouped_config(
                :name,
                name,
                {
                  value: "name",
                  location: "nameLocation",
                  gap: "nameGap",
                  rotate: "nameRotate"
                }
              ),
              "categoryType" => category_type,
              "weekdayFormat" => weekday_format,
              "startonSunday" => starton_sunday,
              "monthFormat" => month_format,
              "data" => data,
              "gridIndex" => grid_index
            }
          )
          helper_component("oh-category-axis", config: configuration, &)
        end

        # Add a `oh-value-axis` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-value-axis.html
        #
        # @param name [String, Hash, nil] Name. Use a hash for detailed options.
        # @option name [String, nil] value Name
        # @option name [String, nil] location Name Location
        # @option name [Integer, String, nil] gap Name Gap
        # @option name [String, nil] rotate Name Rotate
        # @param min [String, nil] Min
        # @param max [String, nil] Max
        # @param scale [true, false, String, nil] Do Not Force Scale to Include Zero. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @param grid_index [Integer, String, nil] Grid Index
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def value_axis(name: nil,
                       min: nil,
                       max: nil,
                       scale: nil,
                       grid_index: nil,
                       config: {},
                       &)
          configuration = component_config(
            config,
            {
              **grouped_config(
                :name,
                name,
                {
                  value: "name",
                  location: "nameLocation",
                  gap: "nameGap",
                  rotate: "nameRotate"
                }
              ),
              "min" => min,
              "max" => max,
              "scale" => scale,
              "gridIndex" => grid_index
            }
          )
          helper_component("oh-value-axis", config: configuration, &)
        end

        # Add a `oh-time-axis` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-time-axis.html
        #
        # @param name [String, Hash, nil] Name. Use a hash for detailed options.
        # @option name [String, nil] value Name
        # @option name [String, nil] location Name Location
        # @option name [Integer, String, nil] gap Name Gap
        # @option name [String, nil] rotate Name Rotate
        # @param grid_index [Integer, String, nil] Grid Index
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def time_axis(name: nil,
                      grid_index: nil,
                      config: {},
                      &)
          configuration = component_config(
            config,
            {
              **grouped_config(
                :name,
                name,
                {
                  value: "name",
                  location: "nameLocation",
                  gap: "nameGap",
                  rotate: "nameRotate"
                }
              ),
              "gridIndex" => grid_index
            }
          )
          helper_component("oh-time-axis", config: configuration, &)
        end

        # Add a `oh-calendar-axis` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-calendar-axis.html
        #
        # @param orient [String, nil] Orientation
        # @param grid_index [Integer, String, nil] Grid Index
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
        def calendar_axis(orient: nil,
                          grid_index: nil,
                          action: nil,
                          config: {},
                          &)
          configuration = component_config(
            config,
            {
              "orient" => orient,
              "gridIndex" => grid_index,
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
          helper_component("oh-calendar-axis", config: configuration, &)
        end

        # Add a `oh-data-series` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-data-series.html
        #
        # @param type [String, nil] Type
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
        def data_series(type: nil,
                        action: nil,
                        config: {},
                        &)
          configuration = component_config(
            config,
            {
              "type" => type,
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
          helper_component("oh-data-series", config: configuration, &)
        end

        # Add a `oh-time-series` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-time-series.html
        #
        # @param name [String, nil] Name
        # @param item [String, Core::Items::Item, nil] Item
        # @param service [String, nil] Persistence Service
        # @param no_boundary [true, false, String, nil] Don't Include Boundary. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param no_item_state [true, false, String, nil] Don't Include Item State. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @param offset [Hash, nil] Offset options. Use a hash for detailed options.
        # @option offset [Integer, String, nil] amount Offset Amount
        # @option offset [String, nil] unit Offset Unit
        # @param markers [String, nil] Markers
        # @param type [String, nil] Type
        # @param x_axis_index [Integer, String, nil] X Axis Index
        # @param y_axis_index [Integer, String, nil] Y Axis Index
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
        def time_series(name: nil,
                        item: nil,
                        service: nil,
                        no_boundary: nil,
                        no_item_state: nil,
                        offset: nil,
                        markers: nil,
                        type: nil,
                        x_axis_index: nil,
                        y_axis_index: nil,
                        action: nil,
                        config: {},
                        &)
          configuration = component_config(
            config,
            {
              "name" => name,
              "item" => item,
              "service" => service,
              "noBoundary" => no_boundary,
              "noItemState" => no_item_state,
              **grouped_config(
                :offset,
                offset,
                {
                  amount: "offsetAmount",
                  unit: "offsetUnit"
                }
              ),
              "markers" => markers,
              "type" => type,
              "xAxisIndex" => x_axis_index,
              "yAxisIndex" => y_axis_index,
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
          helper_component("oh-time-series", config: configuration, &)
        end

        # Add a `oh-state-series` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-state-series.html
        #
        # @param name [String, nil] Name
        # @param item [String, Core::Items::Item, nil] Item
        # @param service [String, nil] Persistence Service
        # @param no_boundary [true, false, String, nil] Don't Include Boundary. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param no_item_state [true, false, String, nil] Don't Include Item State. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @param offset [Hash, nil] Offset options. Use a hash for detailed options.
        # @option offset [Integer, String, nil] amount Offset Amount
        # @option offset [String, nil] unit Offset Unit
        # @param y_value [Numeric, String, nil] Y Value
        # @param y_height [Numeric, String, nil] Y Height
        # @param x_axis_index [Integer, String, nil] X Axis Index
        # @param y_axis_index [Integer, String, nil] Y Axis Index
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
        def state_series(name: nil,
                         item: nil,
                         service: nil,
                         no_boundary: nil,
                         no_item_state: nil,
                         offset: nil,
                         y_value: nil,
                         y_height: nil,
                         x_axis_index: nil,
                         y_axis_index: nil,
                         action: nil,
                         config: {},
                         &)
          configuration = component_config(
            config,
            {
              "name" => name,
              "item" => item,
              "service" => service,
              "noBoundary" => no_boundary,
              "noItemState" => no_item_state,
              **grouped_config(
                :offset,
                offset,
                {
                  amount: "offsetAmount",
                  unit: "offsetUnit"
                }
              ),
              "yValue" => y_value,
              "yHeight" => y_height,
              "xAxisIndex" => x_axis_index,
              "yAxisIndex" => y_axis_index,
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
          helper_component("oh-state-series", config: configuration, &)
        end

        # Add a `oh-aggregate-series` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-aggregate-series.html
        #
        # @param name [String, nil] Name
        # @param item [String, Core::Items::Item, nil] Item
        # @param service [String, nil] Persistence Service
        # @param no_boundary [true, false, String, nil] Don't Include Boundary. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param no_item_state [true, false, String, nil] Don't Include Item State. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @param offset [Hash, nil] Offset options. Use a hash for detailed options.
        # @option offset [Integer, String, nil] amount Offset Amount
        # @option offset [String, nil] unit Offset Unit
        # @param markers [String, nil] Markers
        # @param type [String, nil] Type
        # @param dimension1 [String, nil] First Dimension
        # @param dimension2 [String, nil] Second Dimension
        # @param transpose [true, false, String, nil] Transpose. A `String` is a MainUI expression that evaluates to a
        #   boolean.
        # @param aggregation_function [String, nil] Aggregation Function
        # @param x_axis_index [Integer, String, nil] X Axis Index
        # @param y_axis_index [Integer, String, nil] Y Axis Index
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
        def aggregate_series(name: nil,
                             item: nil,
                             service: nil,
                             no_boundary: nil,
                             no_item_state: nil,
                             offset: nil,
                             markers: nil,
                             type: nil,
                             dimension1: nil,
                             dimension2: nil,
                             transpose: nil,
                             aggregation_function: nil,
                             x_axis_index: nil,
                             y_axis_index: nil,
                             action: nil,
                             config: {},
                             &)
          configuration = component_config(
            config,
            {
              "name" => name,
              "item" => item,
              "service" => service,
              "noBoundary" => no_boundary,
              "noItemState" => no_item_state,
              **grouped_config(
                :offset,
                offset,
                {
                  amount: "offsetAmount",
                  unit: "offsetUnit"
                }
              ),
              "markers" => markers,
              "type" => type,
              "dimension1" => dimension1,
              "dimension2" => dimension2,
              "transpose" => transpose,
              "aggregationFunction" => aggregation_function,
              "xAxisIndex" => x_axis_index,
              "yAxisIndex" => y_axis_index,
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
          helper_component("oh-aggregate-series", config: configuration, &)
        end

        # Add a `oh-calendar-series` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-calendar-series.html
        #
        # @param name [String, nil] Name
        # @param item [String, Core::Items::Item, nil] Item
        # @param service [String, nil] Persistence Service
        # @param no_boundary [true, false, String, nil] Don't Include Boundary. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param no_item_state [true, false, String, nil] Don't Include Item State. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @param offset [Hash, nil] Offset options. Use a hash for detailed options.
        # @option offset [Integer, String, nil] amount Offset Amount
        # @option offset [String, nil] unit Offset Unit
        # @param type [String, nil] Type
        # @param aggregation_function [String, nil] Aggregation Function
        # @param calendar_index [Integer, String, nil] Calendar Index
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
        def calendar_series(name: nil,
                            item: nil,
                            service: nil,
                            no_boundary: nil,
                            no_item_state: nil,
                            offset: nil,
                            type: nil,
                            aggregation_function: nil,
                            calendar_index: nil,
                            action: nil,
                            config: {},
                            &)
          configuration = component_config(
            config,
            {
              "name" => name,
              "item" => item,
              "service" => service,
              "noBoundary" => no_boundary,
              "noItemState" => no_item_state,
              **grouped_config(
                :offset,
                offset,
                {
                  amount: "offsetAmount",
                  unit: "offsetUnit"
                }
              ),
              "type" => type,
              "aggregationFunction" => aggregation_function,
              "calendarIndex" => calendar_index,
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
          helper_component("oh-calendar-series", config: configuration, &)
        end

        # Add a `oh-chart-tooltip` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-chart-tooltip.html
        #
        # @param show [true, false, String, nil] Show. A `String` is a MainUI expression that evaluates to a boolean.
        # @param orient [String, nil] Orientation
        # @param confine [true, false, String, nil] Confine. A `String` is a MainUI expression that evaluates to a
        #   boolean.
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def chart_tooltip(show: nil,
                          orient: nil,
                          confine: nil,
                          config: {},
                          &)
          configuration = component_config(
            config,
            {
              "show" => show,
              "orient" => orient,
              "confine" => confine
            }
          )
          helper_component("oh-chart-tooltip", config: configuration, &)
        end

        # Add a `oh-chart-visualmap` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-chart-visualmap.html
        #
        # @param show [true, false, String, nil] Show. A `String` is a MainUI expression that evaluates to a boolean.
        # @param min [String, nil] Min
        # @param max [String, nil] Max
        # @param type [String, nil] Type
        # @param orient [String, nil] Orientation
        # @param calculable [true, false, String, nil] Show handles. A `String` is a MainUI expression that evaluates to
        #   a boolean.
        # @param pieces [Integer, String, nil] Number of pieces
        # @param preset_palette [String, nil] Preset color palette
        # @param top [String, nil] Top
        # @param bottom [String, nil] Bottom
        # @param left [String, nil] Left
        # @param right [String, nil] Right
        # @param width [String, nil] Width
        # @param height [String, nil] Height
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def chart_visualmap(show: nil,
                            min: nil,
                            max: nil,
                            type: nil,
                            orient: nil,
                            calculable: nil,
                            pieces: nil,
                            preset_palette: nil,
                            top: nil,
                            bottom: nil,
                            left: nil,
                            right: nil,
                            width: nil,
                            height: nil,
                            config: {},
                            &)
          configuration = component_config(
            config,
            {
              "show" => show,
              "min" => min,
              "max" => max,
              "type" => type,
              "orient" => orient,
              "calculable" => calculable,
              "pieces" => pieces,
              "presetPalette" => preset_palette,
              "top" => top,
              "bottom" => bottom,
              "left" => left,
              "right" => right,
              "width" => width,
              "height" => height
            }
          )
          helper_component("oh-chart-visualmap", config: configuration, &)
        end

        # Add a `oh-chart-datazoom` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-chart-datazoom.html
        #
        # @param type [String, nil] Type
        # @param show [true, false, String, nil] Show. A `String` is a MainUI expression that evaluates to a boolean.
        # @param orient [String, nil] Orientation
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def chart_datazoom(type: nil,
                           show: nil,
                           orient: nil,
                           config: {},
                           &)
          configuration = component_config(
            config,
            {
              "type" => type,
              "show" => show,
              "orient" => orient
            }
          )
          helper_component("oh-chart-datazoom", config: configuration, &)
        end

        # Add a `oh-chart-legend` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-chart-legend.html
        #
        # @param show [true, false, String, nil] Show. A `String` is a MainUI expression that evaluates to a boolean.
        # @param orient [String, nil] Orientation
        # @param top [String, nil] Top
        # @param bottom [String, nil] Bottom
        # @param left [String, nil] Left
        # @param right [String, nil] Right
        # @param width [String, nil] Width
        # @param height [String, nil] Height
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def chart_legend(show: nil,
                         orient: nil,
                         top: nil,
                         bottom: nil,
                         left: nil,
                         right: nil,
                         width: nil,
                         height: nil,
                         config: {},
                         &)
          configuration = component_config(
            config,
            {
              "show" => show,
              "orient" => orient,
              "top" => top,
              "bottom" => bottom,
              "left" => left,
              "right" => right,
              "width" => width,
              "height" => height
            }
          )
          helper_component("oh-chart-legend", config: configuration, &)
        end

        # Add a `oh-chart-title` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-chart-title.html
        #
        # @param show [true, false, String, nil] Show. A `String` is a MainUI expression that evaluates to a boolean.
        # @param text [String, nil] Title
        # @param subtext [String, nil] Subtitle
        # @param top [String, nil] Top
        # @param bottom [String, nil] Bottom
        # @param left [String, nil] Left
        # @param right [String, nil] Right
        # @param width [String, nil] Width
        # @param height [String, nil] Height
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def chart_title(show: nil,
                        text: nil,
                        subtext: nil,
                        top: nil,
                        bottom: nil,
                        left: nil,
                        right: nil,
                        width: nil,
                        height: nil,
                        config: {},
                        &)
          configuration = component_config(
            config,
            {
              "show" => show,
              "text" => text,
              "subtext" => subtext,
              "top" => top,
              "bottom" => bottom,
              "left" => left,
              "right" => right,
              "width" => width,
              "height" => height
            }
          )
          helper_component("oh-chart-title", config: configuration, &)
        end

        # Add a `oh-chart-toolbox` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-chart-toolbox.html
        #
        # @param show [true, false, String, nil] Show. A `String` is a MainUI expression that evaluates to a boolean.
        # @param preset_features [String, nil] Features
        # @param top [String, nil] Top
        # @param bottom [String, nil] Bottom
        # @param left [String, nil] Left
        # @param right [String, nil] Right
        # @param width [String, nil] Width
        # @param height [String, nil] Height
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def chart_toolbox(show: nil,
                          preset_features: nil,
                          top: nil,
                          bottom: nil,
                          left: nil,
                          right: nil,
                          width: nil,
                          height: nil,
                          config: {},
                          &)
          configuration = component_config(
            config,
            {
              "show" => show,
              "presetFeatures" => preset_features,
              "top" => top,
              "bottom" => bottom,
              "left" => left,
              "right" => right,
              "width" => width,
              "height" => height
            }
          )
          helper_component("oh-chart-toolbox", config: configuration, &)
        end
      end
    end
  end
end
