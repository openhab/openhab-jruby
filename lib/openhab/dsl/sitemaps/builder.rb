# frozen_string_literal: true

module OpenHAB
  module DSL
    #
    # Contains the various builders for sitemap elements.
    #
    module Sitemaps
      # @!visibility private
      org.openhab.core.model.sitemap.sitemap.impl.SitemapImpl.alias_method :uid, :name

      #
      # A sitemap builder allows you to dynamically create openHAB sitemaps at runtime.
      #
      # @example
      #   sitemaps.build do
      #     sitemap "demo", label: "My home automation" do
      #       frame label: "Date" do
      #         text item: Date
      #       end
      #       frame label: "Demo" do
      #         switch item: Lights, icon: "light"
      #         text item: LR_Temperature, label: "Livingroom [%.1f °C]"
      #         group item: Heating
      #         text item: LR_Multimedia_Summary, label: "Multimedia [%s]", static_icon: "video" do
      #           selection item: LR_TV_Channel,
      #                     mappings: { 0 => "off", 1 => "DasErste", 2 => "BBC One", 3 => "Cartoon Network" }
      #           slider item: LR_TV_Volume
      #         end
      #       end
      #     end
      #   end
      #
      # @see https://www.openhab.org/docs/ui/sitemaps.html
      # @see OpenHAB::DSL.sitemaps
      # @see OpenHAB::Core::Sitemaps::Provider#build sitemaps.build
      #
      class Builder
        # @!visibility private
        def initialize(provider, builder_proxy, update:)
          @provider = provider
          @builder_proxy = builder_proxy
          @update = update
        end

        # (see SitemapBuilder#initialize)
        # @!method sitemap(name, label: nil, icon: nil, &block)
        # @yield Block executed in the context of a {SitemapBuilder}
        # @return [SitemapBuilder]
        # @!visibility public
        def sitemap(name, label: nil, icon: nil, &block)
          sitemap = SitemapBuilder.new(name, @builder_proxy, label:, icon:, &block)
          sitemap = sitemap.build
          if @update && @provider.get(sitemap.uid)
            @provider.update(sitemap)
          else
            @provider.add(sitemap)
          end
        end
      end

      # Base class for all widgets
      # @see org.openhab.core.model.sitemap.sitemap.Widget
      class WidgetBuilder
        include Core::EntityLookup

        # This is copied out of UIComponentSitemapProvider.java
        # The original pattern will match plain state e.g. "ON" as item="O" and state="N"
        # this pattern is modified so it matches as item=nil and state="ON" by using atomic grouping `(?>subexpression)`
        CONDITION_PATTERN = /(?>(?<item>[A-Za-z]\w*)?\s*(?<condition>==|!=|<=|>=|<|>))?\s*(?<sign>\+|-)?(?<state>.+)/
        private_constant :CONDITION_PATTERN

        # @return [String, nil]
        attr_accessor :label
        # The item whose state to show
        # @return [String, Core::Items::Item, nil]
        attr_accessor :item
        # The icon to show
        # It can be a string, or a hash of conditions and icons.
        # @example A simple icon
        #   sitemaps.build { text icon: "f7:house" }
        #
        # @example A dynamic icon with conditions
        #   sitemaps.build do
        #     text item: Wifi_Status, icon: {
        #       "ON" => "f7:wifi",
        #       "OFF" => "f7:wifi_slash",
        #       default: "f7:wifi_exclamationmark"
        #     }
        #   end
        #
        # @return [String, Hash<String, String>, Hash<Array<String>, String>, nil]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#icons
        attr_accessor :icon
        # The static icon to show
        # This is mutually exclusive with {#icon}
        # @return [String, nil]
        # @since openHAB 4.1
        # @see https://www.openhab.org/docs/ui/sitemaps.html#element-types
        attr_accessor :static_icon
        # Label color rules
        # @return [Hash<String, String>, Hash<Array<String>, String>]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#label-value-and-icon-colors
        attr_reader :label_colors
        # Value color rules
        # @return [Hash<String, String>, Hash<Array<String>, String>]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#label-value-and-icon-colors
        attr_reader :value_colors
        # Icon color rules
        # @return [Hash<String, String>, Hash<Array<String>, String>]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#label-value-and-icon-colors
        attr_reader :icon_colors
        # Visibility rules
        # @return [Array<String>]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#visibility
        attr_reader :visibilities

        # @param item [String, Core::Items::Item, nil] The item whose state to show (see {#item})
        # @param label [String, nil] (see {#label})
        # @param icon [String, Hash<String, String>, Hash<Array<String>, String>, nil] (see {#icon})
        # @param static_icon [String, nil] (see {#static_icon})
        # @param label_color [String, Hash<String, String>, Hash<Array<String>, String>, nil]
        #   One or more label color rules (see {#label_color})
        # @param value_color [String, Hash<String, String>, Hash<Array<String>, String>, nil]
        #   One or more value color rules (see {#value_color})
        # @param icon_color [String, Hash<String, String>, Hash<Array<String>, String>, nil]
        #   One or more icon color rules (see {#icon_color})
        # @param visibility [String,
        #                    Core::Types::State,
        #                    Array<String>,
        #                    Array<Core::Types::State>,
        #                    Array<Array<String>>,
        #                    nil]
        #   One or more visibility rules (see {#visibility})
        # @!visibility private
        def initialize(type,
                       builder_proxy,
                       item: nil,
                       label: nil,
                       icon: nil,
                       static_icon: nil,
                       label_color: nil,
                       value_color: nil,
                       icon_color: nil,
                       visibility: nil,
                       &block)
          unless SitemapBuilder.factory.respond_to?(:"create_#{type}")
            raise ArgumentError,
                  "#{type} is not a valid widget type"
          end

          @type = type
          @builder_proxy = builder_proxy
          @item = item
          @label = label
          @icon = icon
          @static_icon = static_icon
          @visibilities = []
          @label_colors = {}
          @value_colors = {}
          @icon_colors = {}

          self.label_color(label_color) if label_color
          self.value_color(value_color) if value_color
          self.icon_color(icon_color) if icon_color
          self.visibility(*visibility) if visibility

          return unless block

          @builder_proxy ||= SimpleDelegator.new(nil) if block.arity == 1

          if @builder_proxy
            old_obj = @builder_proxy.__getobj__
            @builder_proxy.__setobj__(self)
            DSL::ThreadLocal.thread_local(openhab_create_dummy_items: true) do
              yield @builder_proxy
            ensure
              @builder_proxy.__setobj__(old_obj)
            end
          else
            instance_eval_with_dummy_items(&block)
          end
        end

        # Adds one or more new rules for setting the label color
        # @return [Hash<String, String>] the current rules
        def label_color(rules)
          rules = { default: rules } if rules.is_a?(String)
          @label_colors.merge!(rules)
        end

        # Adds one or more new rules for setting the value color
        # @return [Hash<String, String>] the current rules
        def value_color(rules)
          rules = { default: rules } if rules.is_a?(String)
          @value_colors.merge!(rules)
        end

        # Adds one or more new rules for setting the icon color
        # @return [Hash<String, String>] the current rules
        def icon_color(rules)
          rules = { default: rules } if rules.is_a?(String)
          @icon_colors.merge!(rules)
        end

        # Adds one or more new visibility rules
        # @return [Array<String>] the current rules
        def visibility(*rules)
          @visibilities.concat(rules)
        end

        # @!visibility private
        def build
          widget = SitemapBuilder.factory.send(:"create_#{@type}")
          item = @item
          item = item.name if item.respond_to?(:name)
          widget.item = item if item
          widget.label = @label

          raise ArgumentError, "icon and static_icon are mutually exclusive" if icon && static_icon

          if static_icon
            widget.static_icon = static_icon
          elsif icon.is_a?(String)
            widget.icon = @icon
          elsif icon.is_a?(Hash)
            add_icons(widget)
          elsif !icon.nil?
            raise ArgumentError, "icon must be a String or a Hash"
          end

          add_colors(widget, :label_color, label_colors)
          add_colors(widget, :value_color, value_colors)
          add_colors(widget, :icon_color, icon_colors)

          add_conditions(widget, :visibility, visibilities, :create_visibility_rule)

          widget
        end

        # @!visibility private
        def inspect
          s = "#<OpenHAB::DSL::Sitemaps::#{@type.capitalize}Builder "
          s << (instance_variables - [:@children]).map do |iv|
            "#{iv}=#{instance_variable_get(iv).inspect}"
          end.join(" ")
          s << ">"
          s.freeze
        end

        private

        def add_colors(widget, method, colors)
          # ensure that the default color is at the end, and make the conditions nil (no conditions)
          colors.delete(:default)&.tap { |default_color| colors.merge!(nil => default_color) }

          add_conditions(widget, method, colors.keys, :create_color_array) do |color_array, key|
            color_array.arg = colors[key]
          end
        end

        def add_icons(widget)
          icon.delete(:default)&.tap { |default_icon| icon.merge!(nil => default_icon) }
          add_conditions(widget, :icon_rules, icon.keys, :create_icon_rule) do |icon_array, key|
            icon_array.arg = icon[key]
          end
        end

        def add_conditions(widget, method, conditions, container_method)
          return if conditions.empty?

          object = widget.send(method)

          conditions.each do |sub_conditions|
            container = SitemapBuilder.factory.send(container_method)

            add_conditions_to_container(container, sub_conditions)
            yield container, sub_conditions if block_given?
            object.add(container)
          end
        end

        def add_conditions_to_container(container, conditions)
          Array.wrap(conditions).each do |c|
            c = c.to_s if c.is_a?(Core::Types::State)
            unless c.is_a?(String) || c.is_a?(Symbol)
              raise ArgumentError, "#{c.inspect} is not a valid condition data type for #{inspect}"
            end
            unless (match = CONDITION_PATTERN.match(c))
              raise ArgumentError, "Syntax error in condition #{c.inspect} for #{inspect}"
            end

            condition = SitemapBuilder.factory.create_condition
            condition.item = match["item"]
            condition.condition = match["condition"]
            condition.sign = match["sign"]
            condition.state = match["state"]
            container.conditions.add(condition)
          end
        end
      end

      # Builds a `Switch` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-switch
      # @see org.openhab.core.model.sitemap.sitemap.Switch
      class SwitchBuilder < WidgetBuilder
        # Mappings from command to label
        #
        # If a hash is given, the keys are the commands and the values are the labels.
        # The keys can be any {Core::Types::Command command}, string or symbol.
        # They will be converted to strings.
        #
        # If an array is given:
        # - Scalar elements define the command, and the label is the same as the command.
        # - Array elements contain the command, label, and optional third element for the icon.
        # - Hash elements contain the `command`, `release` (optional), `label`, and `icon` (optional)
        #   defined by the corresponding keys.
        #
        # @since openHAB 4.1 added support for icons
        #
        # @example A Hash to specify different command and label
        #   switch mappings: { off: "Off", cool: "Cool", heat: "Heat" }
        #
        # @example A simple array with the same command and label
        #   switch mappings: %w[off cool heat]
        #
        # @example An array of arrays containing the command, label, and icon
        #   switch mappings: [
        #     %w[off Off f7:power],
        #     %w[cool Cool f7:snow],
        #     %w[heat Heat f7:flame],
        #     %w[auto Auto] # no icon
        #   ]
        #
        # @example An array of hashes for the command, label, and icon
        #   switch mappings: [
        #     {command: "off", label: "Off", icon: "f7:power"},
        #     {command: "cool", label: "Cool", icon: "f7:snow"},
        #     {command: "heat", label: "Heat", icon: "f7:flame"},
        #     {command: "auto", label: "Auto"} # no icon
        #   ]
        #
        # @example Since openHAB 4.2, `release` is also supported in the array of hashes
        #   # when `release` is specified, `command` will be sent on press and `release` on release
        #   switch mappings: [
        #     {label: "On", command: ON, release: OFF, icon: "f7:power"}
        #   ]
        #
        # @return [Hash, Array, nil]
        # @see LinkableWidgetBuilder#switch
        # @see https://www.openhab.org/docs/ui/sitemaps.html#mappings
        attr_accessor :mappings

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, mappings: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param mappings [Hash, Array, nil] Mappings from command to label (see {SwitchBuilder#mappings})
        # @!visibility private
        def initialize(type, builder_proxy, mappings: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @mappings = mappings
        end

        # @!visibility private
        def build
          widget = super
          mappings&.each do |cmd, label, icon|
            mapping = SitemapBuilder.factory.create_mapping
            cmd, release_cmd, label, icon = cmd.values_at(:command, :release, :label, :icon) if cmd.is_a?(Hash)
            mapping.cmd = cmd.to_s
            mapping.release_cmd = release_cmd.to_s unless release_cmd.nil?
            mapping.label = label&.to_s || cmd.to_s
            # @deprecated OH 4.1 the if check is not needed in OH4.1+
            mapping.icon = icon if icon
            widget.mappings.add(mapping)
          end
          widget
        end
      end

      # Builds a `Selection` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-selection
      # @see org.openhab.core.model.sitemap.sitemap.Selection
      class SelectionBuilder < SwitchBuilder
      end

      # Builds a `Setpoint` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-setpoint
      # @see org.openhab.core.model.sitemap.sitemap.Setpoint
      class SetpointBuilder < WidgetBuilder
        # Allowed range of the value
        # @return [Range, nil]
        attr_accessor :range
        # How far the value will change with each button press
        # @return [Numeric, nil]
        attr_accessor :step

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, range: nil, step: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param range [Range, nil] Allowed range of the value (see {SetpointBuilder#range})
        # @param step [Numeric,nil] How far the value will change with each button press (see {SetpointBuilder#step})
        # @!visibility private
        def initialize(type, builder_proxy, range: nil, step: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @range = range
          @step = step
        end

        # @!visibility private
        def build
          widget = super
          widget.min_value = range&.begin&.to_d
          widget.max_value = range&.end&.to_d
          widget.step = step&.to_d
          widget
        end
      end

      # Builds a `Slider` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-slider
      # @see org.openhab.core.model.sitemap.sitemap.Slider
      class SliderBuilder < SetpointBuilder
        # How often to send requests (in seconds)
        # @return [Numeric, nil]
        attr_accessor :frequency
        # A short press on the item toggles the item on or off
        # @return [true, false, nil]
        # @note This parameter only works on Android
        attr_writer :switch
        # Only send the command when the slider is released
        # @return [true, false, nil]
        attr_writer :release_only

        # (see SetpointBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, range: nil, step: nil, switch: nil, frequency: nil, release_only: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param switch [true, false, nil]
        #   A short press on the item toggles the item on or off (see {SliderBuilder#switch=})
        # @param frequency [Numeric, nil]
        #   How often to send requests (in seconds) (see {SliderBuilder#frequency})
        # @param release_only [true, false, nil]
        #   Only send the command when the slider is released (see {SliderBuilder#release_only=})
        # @!visibility private
        def initialize(type, builder_proxy, switch: nil, frequency: nil, release_only: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @switch = switch
          @frequency = frequency
          @release_only = release_only
        end

        # (see #switch=)
        def switch?
          @switch
        end

        # (see #release_only=)
        def release_only?
          @release_only
        end

        # @!visibility private
        def build
          widget = super
          widget.switch_enabled = switch? unless @switch.nil?
          widget.send_frequency = (frequency * 1000).to_i if frequency
          # @deprecated OH 4.1 remove the version check when dropping OH 4.1 support
          widget.release_only = release_only? if OpenHAB::Core.version >= OpenHAB::Core::V4_2 && !@release_only.nil?
          widget
        end
      end

      # Builds a `Video` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-video
      # @see org.openhab.core.model.sitemap.sitemap.Video
      class VideoBuilder < WidgetBuilder
        # Valid {#encoding} values
        VALID_ENCODINGS = %i[mjpeg hls].freeze

        # @return [String, nil]
        attr_accessor :url
        # @return [:mjpeg, :hls, nil]
        attr_reader :encoding

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, url: nil, encoding: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param [String, nil] url (see {VideoBuilder#url})
        # @param [:mjpeg, :hls, nil] encoding (see {VideoBuilder#encoding})
        # @!visibility private
        def initialize(type, builder_proxy, url: nil, encoding: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @url = url
          self.encoding = encoding
        end

        def encoding=(value)
          raise ArgumentError, "#{value} is not a valid encoding" if value && !VALID_ENCODINGS.include?(value)

          @encoding = value
        end

        # @!visibility private
        def build
          widget = super
          widget.url = url
          widget.encoding = encoding&.to_s
          widget
        end
      end

      # Builds a `Chart` element
      # See https://www.openhab.org/docs/ui/sitemaps.html#element-type-chart
      # @see org.openhab.core.model.sitemap.sitemap.Chart
      class ChartBuilder < WidgetBuilder
        # Valid {#period} values
        VALID_PERIODS = %i[h 4h 8h 12h D 2D 3D W 2W M 2M 4M Y].freeze

        # The persistence service to use
        # @return [String, nil]
        attr_accessor :service
        # How often to refresh the chart (in seconds)
        # @return [Numeric, nil]
        attr_accessor :refresh
        # Time axis scale
        # @return [:h, :"4h", :"8h", :"12h", :D, :"2D", :"3D", :W, :"2W", :M, :"2M", :"4M", :Y, nil]
        attr_reader :period
        # Always show the legend, never show the legend, or automatically show
        # the legend if there is more than one series in the chart.
        # @return [true, false, nil]
        attr_writer :legend
        # Show the value of a {Core::Items::GroupItem GroupItem} instead of
        # showing a graph for each member (which is the default).
        # @return [true, false, nil]
        attr_writer :group
        # Formatting string for values on the y axis.
        # @return [String, nil]
        # @example
        #   "#.##" # => formats a number with two decimals.
        # @see java.text.DecimalFormat DecimalFormat
        attr_accessor :y_axis_pattern

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, service: nil, refresh: nil, period: nil, legend: nil, group: nil, y_axis_pattern: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param service [String, nil]
        #   The persistence service to use (see {ChartBuilder#service})
        # @param refresh [Numeric, nil)]
        #   How often to refresh the chart (in seconds) (see {ChartBuilder#refresh})
        # @param period [:h, :"4h", :"8h", :"12h", :D, :"2D", :"3D", :W, :"2W", :M, :"2M", :"4M", :Y, nil]
        #   Time axis scale (see {ChartBuilder#period})
        # @param legend [true, false, nil]
        #   Always show the legend (see {ChartBuilder#legend=})
        # @param group [true, false, nil]
        #   Show the value of a group item, instead of its members (see {ChartBuilder#group=})
        # @param y_axis_pattern [String, nil]
        #   Formatting string for values on the y axis (see {ChartBuilder#y_axis_pattern})
        # @!visibility private
        def initialize(type,
                       builder_proxy,
                       service: nil,
                       refresh: nil,
                       period: nil,
                       legend: nil,
                       group: nil,
                       y_axis_pattern: nil,
                       **kwargs,
                       &block)
          super(type, builder_proxy, **kwargs, &block)

          @service = service
          self.refresh = refresh
          @period = period
          @legend = legend
          @group = group
          @y_axis_pattern = y_axis_pattern
        end

        def period=(value)
          value = value&.to_sym
          raise ArgumentError, "#{value} is not a valid period" if value && !VALID_PERIODS.include?(value)

          @period = value
        end

        # (see #legend=)
        def legend?
          @legend
        end

        # (see #group=)
        def group?
          @group
        end

        # @!visibility private
        def build
          widget = super
          widget.service = service
          widget.period = period&.to_s
          widget.legend = legend?
          widget.force_as_item = group?
          widget.yaxis_decimal_pattern = y_axis_pattern
          widget
        end
      end

      # Builds a `Default` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-default
      # @see org.openhab.core.model.sitemap.sitemap.Default
      class DefaultBuilder < WidgetBuilder
        # @return [Integer] The number of element rows to fill
        attr_accessor :height

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, height: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param height [Integer] The number of element rows to fill (see {DefaultBuilder#height})
        # @!visibility private
        def initialize(type, builder_proxy, height: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @height = height
        end

        # @!visibility private
        def build
          widget = super
          widget.height = height
          widget
        end
      end

      # Builds a `Webview` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-webview
      # @see org.openhab.core.model.sitemap.sitemap.Webview
      class WebviewBuilder < DefaultBuilder
        # @return [String, nil]
        attr_accessor :url

        # (see DefaultBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, url: nil, height: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param url [String, nil] (see {WebviewBuilder#url})
        # @!visibility private
        def initialize(type, builder_proxy, url: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @url = url
        end

        # @!visibility private
        def build
          widget = super
          widget.url = url
          widget
        end
      end

      # Builds a `Colorpicker` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-colorpicker
      # @see org.openhab.core.model.sitemap.sitemap.Colorpicker
      class ColorpickerBuilder < WidgetBuilder
        # @return [Numeric, nil]
        #   How often to send requests (in seconds)
        attr_accessor :frequency

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, frequency: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param frequency [Numeric, nil] How often to send requests (see {ColorpickerBuilder#frequency})
        # @!visibility private
        def initialize(type, builder_proxy, frequency: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @frequency = frequency
        end

        # @!visibility private
        def build
          widget = super
          widget.frequency = (frequency * 1000).to_i if frequency
          widget
        end
      end

      # Builds a `Colortemperaturepicker` element
      # @since openHAB 4.3
      # @see org.openhab.core.model.sitemap.sitemap.Colortemperaturepicker
      class ColortemperaturepickerBuilder < WidgetBuilder
        # Allowed range of the value
        # @return [Range, nil]
        attr_accessor :range

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, range: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param range [Range, nil] Allowed range of the value (see {ColortemperaturepickerBuilder#range})
        # @!visibility private
        def initialize(type, builder_proxy, range: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @range = range
        end

        # @!visibility private
        def build
          widget = super
          widget.min_value = range&.begin&.to_d
          widget.max_value = range&.end&.to_d
          widget
        end
      end

      # Builds a `Mapview` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-mapview
      # @see org.openhab.core.model.sitemap.sitemap.Mapview
      class MapviewBuilder < DefaultBuilder
      end

      # Builds an `Input` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-input
      # @see org.openhab.core.model.sitemap.sitemap.Input
      class InputBuilder < WidgetBuilder
        # Valid {#hint} values
        VALID_HINTS = %i[text number date time datetime].freeze

        # @return [:text, :number, :date, :time, :datetime, nil]
        #   Gives a hint to the user interface to use a widget adapted to a specific use
        attr_reader :hint

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, hint: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param [:text, :number, :date, :time, :datetime, nil] hint
        #   Gives a hint to the user interface to use a widget adapted to a specific use (see {InputBuilder#hint})
        # @!visibility private
        def initialize(type, builder_proxy, hint: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          self.hint = hint
        end

        def hint=(value)
          value = value&.to_sym
          raise ArgumentError, "#{value.inspect} is not a valid hint" if value && !VALID_HINTS.include?(value)

          @hint = value
        end

        # @!visibility private
        def build
          widget = super
          widget.input_hint = hint&.to_s
          widget
        end
      end

      # Builds a `Button` element
      #
      # This element can only exist within a `Buttongrid` element.
      #
      # @since openHAB 4.2
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-button
      # @see org.openhab.core.model.sitemap.sitemap.Button
      class ButtonBuilder < WidgetBuilder
        # The row in which the button is placed
        # @return [Integer]
        attr_accessor :row

        # The column in which the button is placed
        # @return [Integer]
        attr_accessor :column

        # The command to send when the button is pressed
        # @return [String, Command]
        attr_accessor :click

        # The command to send when the button is released
        # @return [String, Command, nil]
        attr_accessor :release

        # Whether the button is stateless
        # @return [true, false, nil]
        attr_writer :stateless

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, row:, column:, click:, release: nil, stateless: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param [Integer] row
        #   The row in which the button is placed (see {ButtonBuilder#row})
        # @param [Integer] column
        #   The column in which the button is placed (see {ButtonBuilder#column})
        # @param [String, Command] click
        #   The command to send when the button is pressed (see {ButtonBuilder#click})
        # @param [String, Command, nil] release
        #   The command to send when the button is released (see {ButtonBuilder#release})
        # @param [true, false, nil] stateless
        #   Whether the button is stateless (see {ButtonBuilder#stateless=})
        #
        # @!visibility private
        def initialize(builder_proxy,
                       row:,
                       column:,
                       click:,
                       release: nil,
                       stateless: nil,
                       **kwargs,
                       &block)
          super(:button, builder_proxy, **kwargs, &block)

          @row = row
          @column = column
          @click = click
          @release = release
          @stateless = stateless
        end

        # (see #stateless=)
        def stateless?
          @stateless
        end

        # @!visibility private
        def build
          if Core.version >= Core::V4_2
            super.tap do |widget|
              widget.row = row
              widget.column = column
              widget.cmd = click.to_s
              widget.release_cmd = release.to_s unless release.nil?
              widget.stateless = stateless? unless @stateless.nil?
            end
          else
            # @deprecated OH 4.1
            # in OH 4.1, the button is a property of the Buttongrid, not a widget
            SitemapBuilder.factory.create_button.tap do |button|
              button.row = row
              button.column = column
              button.cmd = click.to_s
              button.label = label
              button.icon = icon if icon
            end
          end
        end
      end

      # Parent class for builders of widgets that can contain other widgets.
      # @see org.openhab.core.model.sitemap.sitemap.LinkableWidget
      class LinkableWidgetBuilder < WidgetBuilder
        # allow referring to items that don't exist yet
        self.create_dummy_items = true

        # @return [Array<WidgetBuilder>]
        # @!visibility private
        attr_reader :children

        # @!parse
        #   # (see WidgetBuilder#initialize)
        #   # Create a new `Frame` element.
        #   # @yield Block executed in the context of a {FrameBuilder}
        #   # @return [FrameBuilder]
        #   # @!visibility public
        #   def frame(item: nil,
        #             label: nil,
        #             icon: nil,
        #             static_icon: nil,
        #             label_color: nil,
        #             value_color: nil,
        #             icon_color: nil,
        #             visibility: nil)
        #   end
        #
        #   # (see WidgetBuilder#initialize)
        #   # Create a new `Text` element.
        #   # @yield Block executed in the context of a {TextBuilder}
        #   # @return [TextBuilder]
        #   # @!visibility public
        #   def text(item: nil,
        #            label: nil,
        #            icon: nil,
        #            static_icon: nil,
        #            label_color: nil,
        #            value_color: nil,
        #            icon_color: nil,
        #            visibility: nil)
        #   end
        #
        #   # (see WidgetBuilder#initialize)
        #   # Create a new `Group` element.
        #   # @yield Block executed in the context of a {GroupBuilder}
        #   # @return [GroupBuilder]
        #   # @!visibility public
        #   def group(item: nil,
        #             label: nil,
        #             icon: nil,
        #             static_icon: nil,
        #             label_color: nil,
        #             value_color: nil,
        #             icon_color: nil,
        #             visibility: nil)
        #   end
        #
        #   # (see ImageBuilder#initialize)
        #   # Create a new `Image` element.
        #   # @yield Block executed in the context of an {ImageBuilder}
        #   # @return [ImageBuilder]
        #   # @!visibility public
        #   def image(item: nil,
        #             label: nil,
        #             icon: nil,
        #             static_icon: nil,
        #             url: nil,
        #             refresh: nil,
        #             label_color: nil,
        #             value_color: nil,
        #             icon_color: nil,
        #             visibility: nil)
        #   end
        #
        #   # (see VideoBuilder#initialize)
        #   # Create a new `Video` element.
        #   # @yield Block executed in the context of a {VideoBuilder}
        #   # @return [VideoBuilder]
        #   # @!visibility public
        #   def video(item: nil,
        #             label: nil,
        #             icon: nil,
        #             static_icon: nil,
        #             url: nil,
        #             encoding: nil,
        #             label_color: nil,
        #             value_color: nil,
        #             icon_color: nil,
        #             visibility: nil)
        #   end
        #
        #   # (see ChartBuilder#initialize)
        #   # Create a new `Chart` element.
        #   # @yield Block executed in the context of a {ChartBuilder}
        #   # @return [ChartBuilder]
        #   # @!visibility public
        #   def chart(item: nil,
        #             label: nil,
        #             icon: nil,
        #             static_icon: nil,
        #             service: nil,
        #             refresh: nil,
        #             period: nil,
        #             legend: nil,
        #             group: nil,
        #             y_axis_pattern: nil,
        #             label_color: nil,
        #             value_color: nil,
        #             icon_color: nil,
        #             visibility: nil)
        #   end
        #
        #   # (see WebviewBuilder#initialize)
        #   # Create a new `Webview` element.
        #   # @yield Block executed in the context of a {WebviewBuilder}
        #   # @return [WebviewBuilder]
        #   # @!visibility public
        #   def webview(item: nil,
        #               label: nil,
        #               icon: nil,
        #               static_icon: nil,
        #               url: nil,
        #               height: nil,
        #               label_color: nil,
        #               value_color: nil,
        #               icon_color: nil,
        #               visibility: nil)
        #   end
        #
        #   # (see SwitchBuilder#initialize)
        #   # Create a new `Switch` element.
        #   # @yield Block executed in the context of a {SwitchBuilder}
        #   # @return [SwitchBuilder]
        #   # @!visibility public
        #   def switch(item: nil,
        #              label: nil,
        #              icon: nil,
        #              static_icon: nil,
        #              mappings: nil,
        #              label_color: nil,
        #              value_color: nil,
        #              icon_color: nil,
        #              visibility: nil)
        #   end
        #
        #   # (see MapviewBuilder#initialize)
        #   # Create a new `Mapview` element.
        #   # @yield Block executed in the context of a {MapviewBuilder}
        #   # @return [MapviewBuilder]
        #   # @!visibility public
        #   def mapview(item: nil,
        #               label: nil,
        #               icon: nil,
        #               static_icon: nil,
        #               height: nil,
        #               label_color: nil,
        #               value_color: nil,
        #               icon_color: nil,
        #               visibility: nil)
        #   end
        #
        #   # (see SliderBuilder#initialize)
        #   # Create a new `Slider` element.
        #   # @yield Block executed in the context of a {SliderBuilder}
        #   # @return [SliderBuilder]
        #   # @!visibility public
        #   def slider(item: nil,
        #              label: nil,
        #              icon: nil,
        #              static_icon: nil,
        #              range: nil,
        #              step: nil,
        #              switch: nil,
        #              frequency: nil,
        #              release_only: nil,
        #              label_color: nil,
        #              value_color: nil,
        #              icon_color: nil,
        #              visibility: nil)
        #   end
        #
        #   # (see SelectionBuilder#initialize)
        #   # Create a new `Selection` element.
        #   # @yield Block executed in the context of a {SelectionBuilder}
        #   # @return [SelectionBuilder]
        #   # @!visibility public
        #   def selection(item: nil,
        #                 label: nil,
        #                 icon: nil,
        #                 static_icon: nil,
        #                 mappings: nil,
        #                 label_color: nil,
        #                 value_color: nil,
        #                 icon_color: nil,
        #                 visibility: nil)
        #   end
        #
        #   # (see InputBuilder#initialize)
        #   # Create a new `Input` element.
        #   # @yield Block executed in the context of an {InputBuilder}
        #   # @return [InputBuilder]
        #   # @since openHAB 4.0
        #   # @!visibility public
        #   def input(item: nil,
        #             label: nil,
        #             icon: nil,
        #             static_icon: nil,
        #             hint: nil,
        #             label_color: nil,
        #             value_color: nil,
        #             icon_color: nil,
        #             visibility: nil)
        #   end
        #
        #   # (see ButtongridBuilder#initialize)
        #   # Create a new `Buttongrid` element.
        #   # @yield Block executed in the context of an {ButtongridBuilder}
        #   # @return [ButtongridBuilder]
        #   # @since openHAB 4.1
        #   # @!visibility public
        #   def buttongrid(item: nil,
        #                  label: nil,
        #                  icon: nil,
        #                  static_icon: nil,
        #                  buttons: nil,
        #                  label_color: nil,
        #                  value_color: nil,
        #                  icon_color: nil,
        #                  visibility: nil)
        #   end
        #
        #   # (see SetpointBuilder#initialize)
        #   # Create a new `Setpoint` element.
        #   # @yield Block executed in the context of a {SetpointBuilder}
        #   # @return [SetpointBuilder]
        #   # @!visibility public
        #   def setpoint(item: nil,
        #               label: nil,
        #               icon: nil,
        #               static_icon: nil,
        #               range: nil,
        #               step: nil,
        #               label_color: nil,
        #               value_color: nil,
        #               icon_color: nil,
        #               visibility: nil)
        #   end
        #
        #   # (see ColorpickerBuilder#initialize)
        #   # Create a new `Colorpicker` element.
        #   # @yield Block executed in the context of a {ColorpickerBuilder}
        #   # @return [ColorpickerBuilder]
        #   # @!visibility public
        #   def colorpicker(item: nil,
        #                   label: nil,
        #                   icon: nil,
        #                   static_icon: nil,
        #                   frequency: nil,
        #                   label_color: nil,
        #                   value_color: nil,
        #                   icon_color: nil,
        #                   visibility: nil)
        #   end
        #
        #   # (see ColortemperaturepickerBuilder#initialize)
        #   # Create a new `Colortemperaturepicker` element.
        #   # @since openHAB 4.3
        #   # @yield Block executed in the context of a {ColortemperaturepickerBuilder}
        #   # @return [ColortemperaturepickerBuilder]
        #   # @!visibility public
        #   def colortemperaturepicker(item: nil,
        #                              label: nil,
        #                              icon: nil,
        #                              static_icon: nil,
        #                              range: nil,
        #                              label_color: nil,
        #                              value_color: nil,
        #                              icon_color: nil,
        #                              visibility: nil)
        #   end
        #
        #   # (see DefaultBuilder#initialize)
        #   # Create a new `Default` element.
        #   # @yield Block executed in the context of a {DefaultBuilder}
        #   # @return [DefaultBuilder]
        #   # @!visibility public
        #   def default(item: nil,
        #              label: nil,
        #              icon: nil,
        #              static_icon: nil,
        #              height: nil,
        #              label_color: nil,
        #              value_color: nil,
        #              icon_color: nil,
        #              visibility: nil)
        #   end
        #

        %i[frame
           text
           group
           image
           video
           chart
           webview
           switch
           mapview
           slider
           selection
           input
           buttongrid
           setpoint
           colorpicker
           colortemperaturepicker
           default].each do |method|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method}(*args, **kwargs, &block)                         # def frame(*args, **kwargs, &block)
              widget = #{method.capitalize}Builder.new(#{method.inspect},  #   widget = FrameBuilder.new(:frame,
                                                       @builder_proxy,     #                             @builder_proxy,
                                                       *args,              #                             *args,
                                                       **kwargs,           #                             **kwargs,
                                                       &block)             #                             &block)
              children << widget                                           #   children << widget
              widget                                                       #   widget
            end                                                            # end
          RUBY
        end

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @!visibility private
        def initialize(*, **)
          @children = []

          super
        end

        # @!visibility private
        def build
          widget = super

          children.each do |child|
            widget.children.add(child.build)
          end

          widget
        end
      end

      # Builds a `Text` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-text
      # @see org.openhab.core.model.sitemap.sitemap.Text
      class TextBuilder < LinkableWidgetBuilder
      end

      # Builds a `Group` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-group
      # @see org.openhab.core.model.sitemap.sitemap.Group
      class GroupBuilder < LinkableWidgetBuilder
      end

      # Builds an `Image` element
      #
      # {WidgetBuilder#item item} can refer to either an
      # {Core::Items::ImageItem ImageItem} whose state is the raw data of the
      # image, or a {Core::Items::StringItem StringItem} whose state is a URL
      # that points to an image.
      #
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-image
      # @see org.openhab.core.model.sitemap.sitemap.Image
      class ImageBuilder < LinkableWidgetBuilder
        # @return [String, nil]
        #   The default URL for the image, if there is no associated item, or
        #   if the associated item's state is not a URL
        attr_accessor :url
        # @return [Numeric, nil] How often to refresh the image (in seconds)
        attr_accessor :refresh

        # (see LinkableWidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, url: nil, refresh: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param url [String, nil] The URL for the image (see {ImageBuilder#url})
        # @param refresh [Numeric, nil] How often to refresh the image (see {ImageBuilder#refresh})
        # @!visibility private
        def initialize(type, builder_proxy, url: nil, refresh: nil, **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          @url = url
          @refresh = refresh
        end

        # @!visibility private
        def build
          widget = super
          widget.url = url
          widget.refresh = (refresh * 1_000).to_i if refresh
          widget
        end
      end

      # Builds a `Frame` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-frame
      # @see org.openhab.core.model.sitemap.sitemap.Frame
      class FrameBuilder < LinkableWidgetBuilder
      end

      # Builds a `Buttongrid` element
      # @since openHAB 4.1
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-buttongrid
      # @see org.openhab.core.model.sitemap.sitemap.Buttongrid
      class ButtongridBuilder < LinkableWidgetBuilder
        REQUIRED_BUTTON_ARGS = %i[row column click].freeze
        private_constant :REQUIRED_BUTTON_ARGS

        # @deprecated OH 4.1 in OH 4.1, Buttongrid is not a LinkableWidget.
        # Pretend that the buttons property is its children so we can add to it in LinkableWidgetBuilder#build
        if (Core::V4_1...Core::V4_2).cover?(Core.version)
          java_import org.openhab.core.model.sitemap.sitemap.Buttongrid
          module Buttongrid
            def children
              buttons
            end
          end
        end

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, static_icon: nil, buttons: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param [Array<Array<int, int, Command, String, String>>] buttons An array of buttons to display.
        #   Each element can be a hash with keyword arguments (see {Sitemaps::ButtongridBuilder#button}),
        #   or an array with the following elements:
        #   - row: 1-12
        #   - column: 1-12
        #   - click: The command to send when the button is pressed
        #   - label: The label to display on the button (optional)
        #   - icon: The icon to display on the button (optional)
        #
        # @example Create a buttongrid with buttons as an argument
        #   # This creates a buttongrid to emulate a TV remote control
        #   sitemaps.build do
        #     sitemap "remote", label: "TV Remote Control" do
        #       buttongrid item: LivingRoom_TV_RCButton, buttons: [
        #         [1, 1, "BACK", "Back", "f7:return"],
        #         [1, 2, "HOME", "Menu", "material:apps"],
        #         [1, 3, "YELLOW", "Search", "f7:search"],
        #         [2, 2, "UP", "Up", "f7:arrowtriangle_up"],
        #         [4, 2, "DOWN", "Down", "f7:arrowtriangle_down"],
        #         [3, 1, "LEFT", "Left", "f7:arrowtriangle_left"],
        #         [3, 3, "RIGHT", "Right", "f7:arrowtriangle_right"],
        #
        #         # Using keyword arguments:
        #         {row: 3, column: 2, click: "ENTER", label: "Enter", icon: "material:adjust" }
        #       ]
        #     end
        #   end
        #
        # @example Create a buttongrid with button widgets
        #   sitemaps.build do
        #     sitemap "remote", label: "TV Remote Control" do
        #       buttongrid item: LivingRoom_TV_RCButton do
        #         button 1, 1, click: "BACK", icon: "f7:return"
        #         button 1, 2, click: "HOME", icon: "material:apps"
        #         button 1, 3, click: "YELLOW", icon: "f7:search"
        #         button 2, 2, click: "UP", icon: "f7:arrowtriangle_up"
        #         button 4, 2, click: "DOWN", icon: "f7:arrowtriangle_down"
        #         button 3, 1, click: "LEFT", icon: "f7:arrowtriangle_left"
        #         button 3, 3, click: "RIGHT", icon: "f7:arrowtriangle_right"
        #         button 3, 2, click: "ENTER", icon: "material:adjust"
        #       end
        #
        #       # The following buttons use widget features introduced in openHAB 4.2+
        #       buttongrid item: LivingRoom_Curtain do
        #         button 1, 1, click: "up", release: "stop", icon: "f7:arrowtriangle_up"
        #         button 2, 1, click: "down", release: "stop", icon: "f7:arrowtriangle_up"
        #       end
        #     end
        #   end
        #
        # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-buttongrid
        # @!visibility private
        def initialize(type, builder_proxy, buttons: [], **kwargs, &block)
          super(type, builder_proxy, **kwargs, &block)

          # Put the buttons given in the constructor before those added in the block
          # We can't do this before calling the super constructor because `children` is initialized there
          children.slice!(0..).then do |buttons_from_block|
            buttons.each do |b|
              if b.is_a?(Array)
                button(*b)
              else
                button(**b)
              end
            end
            children.concat(buttons_from_block)
          end
        end

        #
        # @!method button(row = nil, column = nil, click = nil, label = nil, icon = nil, item: nil, label: nil, icon: nil, static_icon: nil, row:, column:, click:, release: nil, stateless: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # Adds a button inside the buttongrid
        #
        # - In openHAB 4.1, buttons are direct properties of the buttongrid.
        #   Only `row`, `column`, `click`, `label` (optional), and `icon` (optional) are used.
        #   All the other parameters are ignored.
        #   All the buttons will send commands to the same item assigned to the buttongrid.
        #
        # - In openHAB 4.2+, buttons are widgets within the containing buttongrid, and they
        #   support all the parameters listed in the method signature such as
        #   `release`, `label_color`, `visibility`, etc.
        #   Each Button element has an item associated with that button.
        #   When an item is not specified for the button, it will default to the containing buttongrid's item.
        #
        # This method supports positional arguments and/or keyword arguments.
        # Their use can be mixed, however, the keyword arguments will override the positional arguments
        # when both are specified.
        #
        # @param (see ButtonBuilder#initialize)
        # @return [ButtonBuilder]
        #
        # @example Adding buttons to a buttongrid with positional arguments
        #   sitemaps.build do
        #     sitemap "remote" do
        #       buttongrid item: RCButton do
        #         button 1, 1, "BACK", "Back", "f7:return"
        #         button 1, 2, "HOME", "Menu", "material:apps"
        #         button 1, 3, "YELLOW", "Search", "f7:search"
        #         button 2, 2, "UP", "Up", "f7:arrowtriangle_up"
        #         button 4, 2, "DOWN", "Down", "f7:arrowtriangle_down"
        #         button 3, 1, "LEFT", "Left", "f7:arrowtriangle_left"
        #         button 3, 3, "RIGHT", "Right", "f7:arrowtriangle_right"
        #         button 3, 2, "ENTER", "Enter", "material:adjust"
        #       end
        #     end
        #   end
        #
        # @example Adding buttons to a buttongrid with keyword arguments
        #   sitemaps.build do
        #     sitemap "remote" do
        #       buttongrid item: RCButton do
        #         # These buttons will use the default item assigned to the buttongrid (RCButton)
        #         button row: 1, column: 1, click: "BACK", icon: "f7:return"
        #         button row: 1, column: 2, click: "HOME", icon: "material:apps"
        #         button row: 1, column: 3, click: "YELLOW", icon: "f7:search"
        #         button row: 2, column: 2, click: "UP", icon: "f7:arrowtriangle_up"
        #         button row: 4, column: 2, click: "DOWN", icon: "f7:arrowtriangle_down"
        #         button row: 3, column: 1, click: "LEFT", icon: "f7:arrowtriangle_left"
        #         button row: 3, column: 3, click: "RIGHT", icon: "f7:arrowtriangle_right"
        #         button row: 3, column: 2, click: "ENTER", icon: "material:adjust"
        #       end
        #     end
        #   end
        #
        # @example Mixing positional and keyword arguments
        #   sitemaps.build do
        #     sitemap "remote" do
        #       buttongrid item: RCButton do
        #         button 1, 1, click: "BACK", icon: "f7:return"
        #         button 1, 2, click: "HOME", icon: "material:apps"
        #         button 1, 3, click: "YELLOW", icon: "f7:search"
        #         button 2, 2, click: "UP", icon: "f7:arrowtriangle_up"
        #         button 4, 2, click: "DOWN", icon: "f7:arrowtriangle_down"
        #         button 3, 1, click: "LEFT", icon: "f7:arrowtriangle_left"
        #         button 3, 3, click: "RIGHT", icon: "f7:arrowtriangle_right"
        #         button 3, 2, click: "ENTER", icon: "material:adjust"
        #       end
        #     end
        #   end
        #
        # @example openHAB 4.2+ supports assigning different items to buttons, along with additional features
        #   sitemaps.build do
        #     sitemap "remote" do
        #       buttongrid item: RCButton do
        #         button 1, 1, click: "BACK", icon: "f7:return"
        #         button 1, 2, click: "HOME", icon: "material:apps"
        #         button 1, 3, click: "YELLOW", icon: "f7:search", icon_color: "yellow"
        #         button 2, 2, click: "UP", icon: "f7:arrowtriangle_up"
        #         button 4, 2, click: "DOWN", icon: "f7:arrowtriangle_down"
        #         button 3, 1, click: "LEFT", icon: "f7:arrowtriangle_left"
        #         button 3, 3, click: "RIGHT", icon: "f7:arrowtriangle_right"
        #         button 3, 2, click: "ENTER", icon: "material:adjust", icon_color: "red"
        #
        #         # These buttons will use the specified item, only supported in openHAB 4.2+
        #         button 4, 3, click: ON, static_icon: "switch-off", visibility: "TVPower!=ON", item: TVPower
        #         button 4, 3, click: OFF, static_icon: "switch-on", visibility: "TVPower==ON", item: TVPower
        #       end
        #     end
        #   end
        #
        def button(row = nil, column = nil, click = nil, label = nil, icon = nil, **kwargs, &block)
          args = [row, column, click, label, icon].compact

          args = args.first if args.first.is_a?(Array)
          kwargs = %i[row column click label icon].zip(args).to_h.compact.merge(kwargs)

          missing_args = (REQUIRED_BUTTON_ARGS - kwargs.keys).compact
          unless missing_args.empty?
            args = kwargs.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
            missing_args = missing_args.map(&:to_s).join(", ")
            raise ArgumentError, "button(#{args}) missing required parameters: #{missing_args}"
          end

          kwargs[:item] ||= item if item # default to the buttongrid's item
          kwargs[:label] ||= kwargs[:click].to_s

          ButtonBuilder.new(@builder_proxy, **kwargs, &block).tap do |b|
            children << b
          end
        end
      end

      # Builds a `Sitemap`
      # @see https://www.openhab.org/docs/ui/sitemaps.html
      # @see org.openhab.core.model.sitemap.sitemap.Sitemap
      class SitemapBuilder < LinkableWidgetBuilder
        class << self
          # @!visibility private
          def factory
            org.openhab.core.model.sitemap.sitemap.SitemapFactory.eINSTANCE
          end
        end

        # @return [String]
        attr_accessor :name

        private :label_colors, :value_colors, :icon_colors, :visibilities

        undef_method :item, :item=
        undef_method :label_color
        undef_method :value_color
        undef_method :icon_color
        undef_method :visibility
        undef_method :method_missing, :respond_to_missing?

        # @param name [String]
        # @param label [String, nil]
        # @param icon [String, nil]
        # @!visibility private
        def initialize(name, builder_proxy, label: nil, icon: nil)
          super(:sitemap, builder_proxy, label:, icon:)

          @name = name
        end

        # @!visibility private
        def build
          super.tap { |sitemap| sitemap.name = name }
        end
      end
    end
  end
end
