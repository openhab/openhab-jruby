# frozen_string_literal: true

module OpenHAB
  module DSL
    module Pages
      # Tabs within a tabbed page.
      class TabsPageBuilder < PageBuilder
        # Add a tab referencing another page.
        #
        # @param title [String, nil] Tab title
        # @param icon [String, Hash, nil] Tab icon. Use a hash for detailed options.
        # @option icon [String, nil] value Tab icon
        # @param badge [String, Hash, nil] Badge text. Use a hash for detailed options.
        # @option badge [String, nil] value Badge text
        # @option badge [String, nil] color Badge color
        # @param page [String, Hash, nil] Page UID to display. Use a hash for detailed options.
        # @option page [String, nil] value Page UID to display
        # @option page [Hash, nil] config Properties for the referenced page
        # @param config [Hash] Configuration with exact MainUI key names
        # @yield Without an explicit block argument, the block is executed in the context of the
        #   {UI::ComponentBuilder ComponentBuilder}. With an explicit block argument, or when an enclosing block
        #   supplies one, the block retains its surrounding `self`.
        # @yieldparam builder [UI::ComponentBuilder] The component builder
        # @return [UI::ComponentBuilder]
        def tab(title: nil,
                icon: nil,
                badge: nil,
                page: nil,
                config: {},
                &)
          configuration = component_config(
            config,
            {
              "title" => title,
              **grouped_config(
                :icon,
                icon,
                {
                  value: "icon"
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
                :page,
                page,
                {
                  value: "page",
                  config: "pageConfig"
                }
              )
            }
          )
          helper_component("oh-tab", config: configuration, &)
        end
      end
    end
  end
end
