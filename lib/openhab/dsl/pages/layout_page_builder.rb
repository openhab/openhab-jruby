# frozen_string_literal: true

module OpenHAB
  module DSL
    module Pages
      # Layout Components.
      #
      # @see https://www.openhab.org/docs/ui/components/
      #
      class LayoutPageBuilder < PageBuilder
        # Layout containers require layout helpers in their nested blocks.
        # @!visibility private
        def self.component_builder
          self
        end

        # Add a `oh-block` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-block.html
        #
        # @param title [String, nil] Title
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        def block(title: nil,
                  config: {},
                  &)
          configuration = component_config(
            config,
            {
              "title" => title
            }
          )
          helper_component("oh-block", config: configuration, &)
        end

        # Add a `oh-canvas-item` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-canvas-item.html
        #
        # @param not_styled [true, false, String, nil] Preserve classic style. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param no_canvas_shadow [true, false, String, nil] No elements shadow. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        def canvas_item(not_styled: nil,
                        no_canvas_shadow: nil,
                        config: {},
                        &)
          configuration = component_config(
            config,
            {
              "notStyled" => not_styled,
              "noCanvasShadow" => no_canvas_shadow
            }
          )
          helper_component("oh-canvas-item", config: configuration, &)
        end

        # Add a `oh-canvas-layer` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-canvas-layer.html
        #
        # @param layer_name [String, nil] Name
        # @param preload [true, false, String, nil] Pre-load. A `String` is a MainUI expression that evaluates to a
        #   boolean.
        # @param visible [String, Hash, nil] Visible. Use a hash for detailed options.
        # @option visible [String, nil] value Visible
        # @option visible [String, nil] to Visible only to
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        def canvas_layer(layer_name: nil,
                         preload: nil,
                         visible: nil,
                         config: {},
                         &)
          configuration = component_config(
            config,
            {
              "layerName" => layer_name,
              "preload" => preload,
              **grouped_config(
                :visible,
                visible,
                {
                  value: "visible",
                  to: "visibleTo"
                }
              )
            }
          )
          helper_component("oh-canvas-layer", config: configuration, &)
        end

        # Add a `oh-canvas-layout` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-canvas-layout.html
        #
        # @param grid [Integer, String, nil] Grid size
        # @param screen [Hash, nil] Screen options. Use a hash for detailed options.
        # @option screen [Integer, String, nil] width Screen Width
        # @option screen [Integer, String, nil] height Screen Height
        # @param scale [true, false, String, nil] Scaling. A `String` is a MainUI expression that evaluates to a
        #   boolean.
        # @param image [Hash, nil] Image options. Use a hash for detailed options.
        # @option image [String, nil] url Image URL
        # @option image [String, nil] src_set Image Source Set
        # @param embed_svg [true, false, String, Hash, nil] Embed SVG. A `String` is a MainUI expression that evaluates
        #   to a boolean. Use a hash for detailed options.
        # @option embed_svg [true, false, String, nil] value Embed SVG. A `String` is a MainUI expression that evaluates
        #   to a boolean.
        # @option embed_svg [true, false, String, nil] flashing Embed SVG Flashing in Run-Mode. A `String` is a MainUI
        #   expression that evaluates to a boolean.
        # @param hide_navbar [true, false, String, nil] Hide Navigation bar. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param hide_sidebar_icon [true, false, String, nil] Hide Sidebar Icon. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param show_fullscreen_icon [true, false, String, nil] Show Fullscreen Icon. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @param box_shadow [String, nil] Box shadow
        # @param text_shadow [String, nil] Text shadow
        # @param filter_shadow [String, nil] Filter Shadow
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        def canvas_layout(grid: nil,
                          screen: nil,
                          scale: nil,
                          image: nil,
                          embed_svg: nil,
                          hide_navbar: nil,
                          hide_sidebar_icon: nil,
                          show_fullscreen_icon: nil,
                          box_shadow: nil,
                          text_shadow: nil,
                          filter_shadow: nil,
                          config: {},
                          &)
          configuration = component_config(
            config,
            {
              "grid" => grid,
              **grouped_config(
                :screen,
                screen,
                {
                  width: "screenWidth",
                  height: "screenHeight"
                }
              ),
              "scale" => scale,
              **grouped_config(
                :image,
                image,
                {
                  url: "imageUrl",
                  src_set: "imageSrcSet"
                }
              ),
              **grouped_config(
                :embed_svg,
                embed_svg,
                {
                  value: "embedSvg",
                  flashing: "embedSvgFlashing"
                }
              ),
              "hideNavbar" => hide_navbar,
              "hideSidebarIcon" => hide_sidebar_icon,
              "showFullscreenIcon" => show_fullscreen_icon,
              "boxShadow" => box_shadow,
              "textShadow" => text_shadow,
              "filterShadow" => filter_shadow
            }
          )
          helper_component("oh-canvas-layout", config: configuration, &)
        end

        # Add a `oh-grid-col` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-grid-col.html
        #
        # @param width [String, nil] Width
        # @param xsmall [String, nil] Width (XS)
        # @param small [String, nil] Width (S)
        # @param medium [String, nil] Width (M)
        # @param large [String, nil] Width (L)
        # @param xlarge [String, nil] Width (XL)
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        def grid_col(width: nil,
                     xsmall: nil,
                     small: nil,
                     medium: nil,
                     large: nil,
                     xlarge: nil,
                     config: {},
                     &)
          configuration = component_config(
            config,
            {
              "width" => width,
              "xsmall" => xsmall,
              "small" => small,
              "medium" => medium,
              "large" => large,
              "xlarge" => xlarge
            }
          )
          helper_component("oh-grid-col", config: configuration, &)
        end

        # Add a `oh-grid-layout` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-grid-layout.html
        #
        # @param col_num [Integer, String, nil] Number of Columns
        # @param margin [Integer, String, nil] Margin
        # @param vertical_compact [true, false, String, nil] Vertical Compact. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param screen [Hash, nil] Screen options. Use a hash for detailed options.
        # @option screen [Integer, String, nil] width Screen Width
        # @option screen [Integer, String, nil] height Screen Height
        # @param scale [true, false, String, nil] Scaling. A `String` is a MainUI expression that evaluates to a
        #   boolean.
        # @param hide_navbar [true, false, String, nil] Hide Navigation bar. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param hide_sidebar_icon [true, false, String, nil] Hide Sidebar Icon. A `String` is a MainUI expression that
        #   evaluates to a boolean.
        # @param show_fullscreen_icon [true, false, String, nil] Show Fullscreen Icon. A `String` is a MainUI expression
        #   that evaluates to a boolean.
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        def grid_layout(col_num: nil,
                        margin: nil,
                        vertical_compact: nil,
                        screen: nil,
                        scale: nil,
                        hide_navbar: nil,
                        hide_sidebar_icon: nil,
                        show_fullscreen_icon: nil,
                        config: {},
                        &)
          configuration = component_config(
            config,
            {
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
              "hideNavbar" => hide_navbar,
              "hideSidebarIcon" => hide_sidebar_icon,
              "showFullscreenIcon" => show_fullscreen_icon
            }
          )
          helper_component("oh-grid-layout", config: configuration, &)
        end

        # Add a `oh-grid-row` component.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-grid-row.html
        #
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        def grid_row(config: {},
                     &)
          configuration = component_config(
            config,
            {}
          )
          helper_component("oh-grid-row", config: configuration, &)
        end

        # Add a `oh-masonry` component. Direct children of a layout page automatically use its masonry slot. An
        # explicitly selected slot is preserved.
        #
        # @see https://www.openhab.org/docs/ui/components/oh-masonry.html
        #
        # @param flavor [String, nil] Flavor
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}. With an explicit block argument, or when an enclosing block supplies
        #   one, the block retains its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        def masonry(flavor: nil,
                    config: {},
                    &)
          configuration = component_config(
            config,
            {
              "flavor" => flavor
            }
          )
          if @type == "oh-layout-page" && !@explicit_slot
            slot("masonry") { helper_component("oh-masonry", config: configuration, &) }
          else
            helper_component("oh-masonry", config: configuration, &)
          end
        end

        # Add a `oh-grid-item` component.
        #
        # @param x [Integer, nil] Horizontal position in grid units
        # @param y [Integer, nil] Vertical position in grid units
        # @param w [Integer, nil] Width in grid units
        # @param h [Integer, nil] Height in grid units
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {LayoutPageBuilder LayoutPageBuilder}.
        #   With an explicit block argument, or when an enclosing block supplies one, the block retains
        #   its surrounding `self`.
        # @yieldparam builder [LayoutPageBuilder] The component builder
        # @return [LayoutPageBuilder]
        # rubocop:disable-next Naming/MethodParameterName -- MainUI names its grid coordinates x, y, w, and h.
        def grid_item(x: nil,
                      y: nil,
                      w: nil,
                      h: nil,
                      config: {},
                      &)
          configuration = component_config(
            config,
            {
              "x" => x,
              "y" => y,
              "w" => w,
              "h" => h
            }
          )
          helper_component("oh-grid-item", config: configuration, &)
        end
      end
    end
  end
end
