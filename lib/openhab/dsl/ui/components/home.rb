# frozen_string_literal: true

module OpenHAB
  module DSL
    module UI
      module Components
        # Home Page Cards.
        #
        # @see https://www.openhab.org/docs/ui/components/
        #
        module Home
          # Add a `oh-location-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-location-card.html
          #
          # @param item [String, Core::Items::Item, nil] Item
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param background [Hash, nil] Background options. Use a hash for detailed options.
          # @option background [String, nil] color Background Color
          # @option background [String, nil] image Background Image
          # @param invert_text [true, false, String, nil] Invert Text. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @param disable_badges [true, false, String, nil] Disable badges. A `String` is a MainUI expression that
          #   evaluates to a boolean.
          # @param badges [String, nil] Enabled badges
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def location_card(item: nil,
                            title: nil,
                            subtitle: nil,
                            background: nil,
                            invert_text: nil,
                            disable_badges: nil,
                            badges: nil,
                            config: {},
                            &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "title" => title,
                "subtitle" => subtitle,
                **grouped_config(
                  :background,
                  background,
                  {
                    color: "backgroundColor",
                    image: "backgroundImage"
                  }
                ),
                "invertText" => invert_text,
                "disableBadges" => disable_badges,
                "badges" => badges
              }
            )
            helper_component("oh-location-card", config: configuration, &)
          end

          # Add a `oh-equipment-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-equipment-card.html
          #
          # @param item [String, nil] Item
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param background [Hash, nil] Background options. Use a hash for detailed options.
          # @option background [String, nil] color Background Color
          # @option background [String, nil] image Background Image
          # @param invert_text [true, false, String, nil] Invert Text. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def equipment_card(item: nil,
                             title: nil,
                             subtitle: nil,
                             background: nil,
                             invert_text: nil,
                             config: {},
                             &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "title" => title,
                "subtitle" => subtitle,
                **grouped_config(
                  :background,
                  background,
                  {
                    color: "backgroundColor",
                    image: "backgroundImage"
                  }
                ),
                "invertText" => invert_text
              }
            )
            helper_component("oh-equipment-card", config: configuration, &)
          end

          # Add a `oh-property-card` component.
          #
          # @see https://www.openhab.org/docs/ui/components/oh-property-card.html
          #
          # @param item [String, nil] Item
          # @param title [String, nil] Title
          # @param subtitle [String, nil] Subtitle
          # @param background [Hash, nil] Background options. Use a hash for detailed options.
          # @option background [String, nil] color Background Color
          # @option background [String, nil] image Background Image
          # @param invert_text [true, false, String, nil] Invert Text. A `String` is a MainUI expression that evaluates
          #   to a boolean.
          # @param config [Hash] Configuration with exact MainUI key names
          # @yield Without an explicit block argument, the block is executed in the context of the
          #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
          #   supplies one, the block retains its surrounding `self`.
          # @yieldparam builder [UI::ComponentBuilder] The component builder
          # @return [UI::ComponentBuilder]
          def property_card(item: nil,
                            title: nil,
                            subtitle: nil,
                            background: nil,
                            invert_text: nil,
                            config: {},
                            &)
            configuration = component_config(
              config,
              {
                "item" => item,
                "title" => title,
                "subtitle" => subtitle,
                **grouped_config(
                  :background,
                  background,
                  {
                    color: "backgroundColor",
                    image: "backgroundImage"
                  }
                ),
                "invertText" => invert_text
              }
            )
            helper_component("oh-property-card", config: configuration, &)
          end
        end
      end
    end
  end
end
