# frozen_string_literal: true

module OpenHAB
  module DSL
    module Pages
      # Helpers selecting the root component type and available component categories.
      class Builder
        # Build a `oh-layout-page` page.
        #
        # @param uid [String] Unique page identifier
        # @param label [String, nil] Page label
        # @param sidebar [true, false, nil] Display in the sidebar
        # @param order [Integer, nil] Position in the sidebar
        # @param icon [String, Hash, nil] Sidebar icon. Use a hash for detailed options.
        # @option icon [String, nil] value Sidebar icon
        # @param browser_title [String, nil] Browser title
        # @param visible_to [Array<String>, nil] Roles allowed to see this page
        # @param tags [Array<String>] Root component tags
        # @param layout_type [String, nil] Responsive or fixed layout
        # @param fixed_type [String, nil] Grid or canvas for a fixed layout
        # @param hide_navbar [true, false, nil] Hide the navigation bar
        # @param hide_sidebar_icon [true, false, nil] Hide the sidebar icon
        # @param show_fullscreen_icon [true, false, nil] Show the fullscreen icon
        # @param col_num [Integer, nil] Number of fixed grid columns
        # @param margin [Integer, nil] Fixed grid margin
        # @param vertical_compact [true, false, nil] Compact the fixed grid vertically
        # @param screen [Hash, nil] Screen options. Use a hash for detailed options.
        # @option screen [Integer, nil] width Fixed layout width
        # @option screen [Integer, nil] height Fixed layout height
        # @param scale [true, false, nil] Scale a fixed layout to the screen
        # @param grid [Integer, nil] Canvas grid size
        # @param image_url [String, nil] Canvas background image
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The page builder
        # @return [org.openhab.core.ui.components.RootUIComponent]
        def layout_page(uid,
                        label: nil,
                        sidebar: nil,
                        order: nil,
                        icon: nil,
                        browser_title: nil,
                        visible_to: nil,
                        tags: [],
                        layout_type: nil,
                        fixed_type: nil,
                        hide_navbar: nil,
                        hide_sidebar_icon: nil,
                        show_fullscreen_icon: nil,
                        col_num: nil,
                        margin: nil,
                        vertical_compact: nil,
                        screen: nil,
                        scale: nil,
                        grid: nil,
                        image_url: nil,
                        config: {},
                        &)
          configuration = component_config(
            config,
            {
              "label" => label,
              "sidebar" => sidebar,
              "order" => order,
              **grouped_config(
                :icon,
                icon,
                {
                  value: "icon"
                }
              ),
              "browserTitle" => browser_title,
              "visibleTo" => visible_to,
              "layoutType" => layout_type,
              "fixedType" => fixed_type,
              "hideNavbar" => hide_navbar,
              "hideSidebarIcon" => hide_sidebar_icon,
              "showFullscreenIcon" => show_fullscreen_icon,
              "colNum" => col_num,
              "margin" => margin,
              "verticalCompact" => vertical_compact,
              **grouped_config(
                :screen,
                screen,
                {
                  width: "screenWidth",
                  height: "screenHeight"
                }
              ),
              "scale" => scale,
              "grid" => grid,
              "imageUrl" => image_url
            }
          )
          build_page(LayoutPageBuilder,
                     uid,
                     "oh-layout-page",
                     tags:, config: configuration,
                     &)
        end

        # Build a `oh-map-page` page.
        #
        # @param uid [String] Unique page identifier
        # @param initial [Hash, nil] Initial options. Use a hash for detailed options.
        # @option initial [String, nil] center Initial Center
        # @option initial [String, nil] zoom Initial Zoom Level
        # @param no_zoom_or_drag [true, false, String, nil] Disable Zooming & Dragging. A `String` is a MainUI
        #   expression that evaluates to a boolean.
        # @param no_zoom_animation [true, false, String, nil] No Zoom Animation. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param no_marker_zoom_animation [true, false, String, nil] Hide Markers during Zoom Animation. A `String` is a
        #   MainUI expression that evaluates to a boolean.
        # @param tile_layer_provider [String, nil] Provider for the background tiles
        # @param overlay_tile_layer_provider [String, nil] Provider for the overlay tiles
        # @param label [String, nil] Page label
        # @param sidebar [true, false, nil] Display in the sidebar
        # @param order [Integer, nil] Position in the sidebar
        # @param icon [String, Hash, nil] Sidebar icon. Use a hash for detailed options.
        # @option icon [String, nil] value Sidebar icon
        # @param browser_title [String, nil] Browser title
        # @param visible_to [Array<String>, nil] Roles allowed to see this page
        # @param tags [Array<String>] Root component tags
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {MapPageBuilder MapPageBuilder}. With an explicit block argument, or when an enclosing block supplies one,
        #   the block retains its surrounding `self`.
        # @yieldparam builder [MapPageBuilder] The page builder
        # @return [org.openhab.core.ui.components.RootUIComponent]
        def map_page(uid,
                     initial: nil,
                     no_zoom_or_drag: nil,
                     no_zoom_animation: nil,
                     no_marker_zoom_animation: nil,
                     tile_layer_provider: nil,
                     overlay_tile_layer_provider: nil,
                     label: nil,
                     sidebar: nil,
                     order: nil,
                     icon: nil,
                     browser_title: nil,
                     visible_to: nil,
                     tags: [],
                     config: {},
                     &)
          configuration = component_config(
            config,
            {
              **grouped_config(
                :initial,
                initial,
                {
                  center: "initialCenter",
                  zoom: "initialZoom"
                }
              ),
              "noZoomOrDrag" => no_zoom_or_drag,
              "noZoomAnimation" => no_zoom_animation,
              "noMarkerZoomAnimation" => no_marker_zoom_animation,
              "tileLayerProvider" => tile_layer_provider,
              "overlayTileLayerProvider" => overlay_tile_layer_provider,
              "label" => label,
              "sidebar" => sidebar,
              "order" => order,
              **grouped_config(
                :icon,
                icon,
                {
                  value: "icon"
                }
              ),
              "browserTitle" => browser_title,
              "visibleTo" => visible_to
            }
          )
          build_page(MapPageBuilder,
                     uid,
                     "oh-map-page",
                     tags:, config: configuration,
                     &)
        end

        # Build a `oh-plan-page` page.
        #
        # @param uid [String] Unique page identifier
        # @param image [Hash, nil] Image options. Use a hash for detailed options.
        # @option image [String, nil] url Image URL
        # @option image [Integer, String, nil] width Image Width
        # @option image [Integer, String, nil] height Image Height
        # @param no_zoom_or_drag [true, false, String, nil] Disable Zooming & Dragging. A `String` is a MainUI
        #   expression that evaluates to a boolean.
        # @param no_zoom_animation [true, false, String, nil] No Zoom Animation. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param no_marker_zoom_animation [true, false, String, nil] Hide Markers during Zoom Animation. A `String` is a
        #   MainUI expression that evaluates to a boolean.
        # @param background_color [String, nil] Background Color
        # @param dark_mode_invert [true, false, String, nil] Invert Image in Dark Mode. A `String` is a MainUI
        #   expression that evaluates to a boolean.
        # @param tooltip [Hash, nil] Tooltip options. Use a hash for detailed options.
        # @option tooltip [String, nil] color Tooltip Color
        # @param label [String, nil] Page label
        # @param sidebar [true, false, nil] Display in the sidebar
        # @param order [Integer, nil] Position in the sidebar
        # @param icon [String, Hash, nil] Sidebar icon. Use a hash for detailed options.
        # @option icon [String, nil] value Sidebar icon
        # @param browser_title [String, nil] Browser title
        # @param visible_to [Array<String>, nil] Roles allowed to see this page
        # @param tags [Array<String>] Root component tags
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {PlanPageBuilder PlanPageBuilder}. With an explicit block argument, or when an enclosing block supplies one,
        #   the block retains its surrounding `self`.
        # @yieldparam builder [PlanPageBuilder] The page builder
        # @return [org.openhab.core.ui.components.RootUIComponent]
        def plan_page(uid,
                      image: nil,
                      no_zoom_or_drag: nil,
                      no_zoom_animation: nil,
                      no_marker_zoom_animation: nil,
                      background_color: nil,
                      dark_mode_invert: nil,
                      tooltip: nil,
                      label: nil,
                      sidebar: nil,
                      order: nil,
                      icon: nil,
                      browser_title: nil,
                      visible_to: nil,
                      tags: [],
                      config: {},
                      &)
          configuration = component_config(
            config,
            {
              **grouped_config(
                :image,
                image,
                {
                  url: "imageUrl",
                  width: "imageWidth",
                  height: "imageHeight"
                }
              ),
              "noZoomOrDrag" => no_zoom_or_drag,
              "noZoomAnimation" => no_zoom_animation,
              "noMarkerZoomAnimation" => no_marker_zoom_animation,
              "backgroundColor" => background_color,
              "darkModeInvert" => dark_mode_invert,
              **grouped_config(
                :tooltip,
                tooltip,
                {
                  color: "tooltipColor"
                }
              ),
              "label" => label,
              "sidebar" => sidebar,
              "order" => order,
              **grouped_config(
                :icon,
                icon,
                {
                  value: "icon"
                }
              ),
              "browserTitle" => browser_title,
              "visibleTo" => visible_to
            }
          )
          build_page(PlanPageBuilder,
                     uid,
                     "oh-plan-page",
                     tags:, config: configuration,
                     &)
        end
        alias_method :floorplan_page, :plan_page

        # Build a `oh-tabs-page` page.
        #
        # @param uid [String] Unique page identifier
        # @param label [String, nil] Page label
        # @param sidebar [true, false, nil] Display in the sidebar
        # @param order [Integer, nil] Position in the sidebar
        # @param icon [String, Hash, nil] Sidebar icon. Use a hash for detailed options.
        # @option icon [String, nil] value Sidebar icon
        # @param browser_title [String, nil] Browser title
        # @param visible_to [Array<String>, nil] Roles allowed to see this page
        # @param tags [Array<String>] Root component tags
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {TabsPageBuilder TabsPageBuilder}. With an explicit block argument, or when an enclosing block supplies one,
        #   the block retains its surrounding `self`.
        # @yieldparam builder [TabsPageBuilder] The page builder
        # @return [org.openhab.core.ui.components.RootUIComponent]
        def tabs_page(uid,
                      label: nil,
                      sidebar: nil,
                      order: nil,
                      icon: nil,
                      browser_title: nil,
                      visible_to: nil,
                      tags: [],
                      config: {},
                      &)
          configuration = component_config(
            config,
            {
              "label" => label,
              "sidebar" => sidebar,
              "order" => order,
              **grouped_config(
                :icon,
                icon,
                {
                  value: "icon"
                }
              ),
              "browserTitle" => browser_title,
              "visibleTo" => visible_to
            }
          )
          build_page(TabsPageBuilder,
                     uid,
                     "oh-tabs-page",
                     tags:, config: configuration,
                     &)
        end
        alias_method :tabbed_page, :tabs_page

        # Build a `oh-chart-page` page.
        #
        # @param uid [String] Unique page identifier
        # @param chart_type [String, nil] Chart Type
        # @param period [String, nil] Initial Period
        # @param future [Numeric, String, nil] Future Proportion
        # @param label [String, nil] Page label
        # @param sidebar [true, false, nil] Display in the sidebar
        # @param order [Integer, nil] Position in the sidebar
        # @param icon [String, Hash, nil] Sidebar icon. Use a hash for detailed options.
        # @option icon [String, nil] value Sidebar icon
        # @param browser_title [String, nil] Browser title
        # @param visible_to [Array<String>, nil] Roles allowed to see this page
        # @param tags [Array<String>] Root component tags
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {ChartPageBuilder ChartPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [ChartPageBuilder] The page builder
        # @return [org.openhab.core.ui.components.RootUIComponent]
        def chart_page(uid,
                       chart_type: nil,
                       period: nil,
                       future: nil,
                       label: nil,
                       sidebar: nil,
                       order: nil,
                       icon: nil,
                       browser_title: nil,
                       visible_to: nil,
                       tags: [],
                       config: {},
                       &)
          configuration = component_config(
            config,
            {
              "chartType" => chart_type,
              "period" => period,
              "future" => future,
              "label" => label,
              "sidebar" => sidebar,
              "order" => order,
              **grouped_config(
                :icon,
                icon,
                {
                  value: "icon"
                }
              ),
              "browserTitle" => browser_title,
              "visibleTo" => visible_to
            }
          )
          build_page(ChartPageBuilder,
                     uid,
                     "oh-chart-page",
                     tags:, config: configuration,
                     &)
        end
      end
    end
  end
end
