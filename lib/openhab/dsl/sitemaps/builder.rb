# frozen_string_literal: true

module OpenHAB
  module DSL
    #
    # Contains the various builders for sitemap elements.
    #
    module Sitemaps
      # @!visibility private
      org.openhab.core.model.sitemap.sitemap.impl.SitemapImpl.alias_method :uid, :name

      # Base sitemap builder DSL
      class Builder
        # @!visibility private
        def initialize(provider, update:)
          @provider = provider
          @update = update
        end

        # (see SitemapBuilder#initialize)
        # @yield Block executed in the context of a {SitemapBuilder}
        # @return [SitemapBuilder]
        # @!visibility public
        def sitemap(name, label = nil, icon: nil, &block)
          sitemap = SitemapBuilder.new(name, label, icon: icon)
          sitemap.instance_eval_with_dummy_items(&block) if block
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
        # rubocop:disable Layout/LineLength, Lint/MixedRegexpCaptureTypes
        # These are copied directly out of UIComponentSitemapProvider.java
        VISIBILITY_PATTERN = /(?<item>[A-Za-z]\w*)\s*(?<condition>==|!=|<=|>=|<|>)\s*(?<sign>\+|-)?(?<state>\S+)/.freeze
        COLOR_PATTERN = /((?<item>[A-Za-z]\w*)?\s*((?<condition>==|!=|<=|>=|<|>)\s*(?<sign>\+|-)?(?<state>\S+))?\s*=)?\s*(?<arg>\S+)/.freeze
        # rubocop:enable Layout/LineLength, Lint/MixedRegexpCaptureTypes
        private_constant :VISIBILITY_PATTERN, :COLOR_PATTERN

        # @return [String, nil]
        attr_accessor :label
        # The item whose state to show
        # @return [String, Core::Items::Item, nil]
        attr_accessor :item
        # @return [String, nil]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#icons
        attr_accessor :icon
        # Label color rules
        # @return [Array<String>]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#label-value-and-icon-colors
        attr_reader :label_colors
        # Value color rules
        # @return [Array<String>]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#label-value-and-icon-colors
        attr_reader :value_colors
        # Icon color rules
        # @return [Array<String>]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#label-value-and-icon-colors
        attr_reader :icon_colors
        # Visibility rules
        # @return [Array<String>]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#visibility
        attr_reader :visibilities

        # @param item [String, Core::Items::Item, nil] The item whose state to show (see {#item})
        # @param label [String, nil] (see {#label})
        # @param icon [String, nil] (see {#icon})
        # @param label_color [String, Array<String>, nil] One or more label color rules (see {#label_color})
        # @param value_color [String, Array<String>, nil] One or more value color rules (see {#value_color})
        # @param icon_color [String, Array<String>, nil] One or more icon color rules (see {#icon_color})
        # @param visibility [String, Array<String>, nil] One or more visibility rules (see {#visibility})
        # @!visibility private
        def initialize(type,
                       item: nil,
                       label: nil,
                       icon: nil,
                       label_color: nil,
                       value_color: nil,
                       icon_color: nil,
                       visibility: nil)
          unless SitemapBuilder.factory.respond_to?("create_#{type}")
            raise ArgumentError,
                  "#{type} is not a valid widget type"
          end

          @type = type
          @item = item
          @label = label
          @icon = icon
          @visibilities = []
          @label_colors = []
          @value_colors = []
          @icon_colors = []

          self.label_color(*label_color) if label_color
          self.value_color(*value_color) if value_color
          self.icon_color(*icon_color) if icon_color
          self.visibility(*visibility) if visibility
        end

        # Adds one or more new rules for setting the label color
        # @return [Array<String>] the current rules
        def label_color(*rules)
          @label_colors.concat(rules)
        end

        # Adds one or more new rules for setting the value color
        # @return [Array<String>] the current rules
        def value_color(*rules)
          @value_colors.concat(rules)
        end

        # Adds one or more new rules for setting the icon color
        # @return [Array<String>] the current rules
        def icon_color(*rules)
          @icon_colors.concat(rules)
        end

        # Adds one or more new visibility rules
        # @return [Array<String>] the current rules
        def visibility(*rules)
          @visibilities.concat(rules)
        end

        # @!visibility private
        def build
          widget = SitemapBuilder.factory.send("create_#{@type}")
          item = @item
          item = item.name if item.respond_to?(:name)
          widget.item = item if item
          widget.label = @label
          widget.icon = @icon

          add_color(widget.label_color, label_colors) unless label_colors.empty?
          add_color(widget.value_color, value_colors) unless value_colors.empty?
          add_color(widget.icon_color, icon_colors) unless icon_colors.empty?

          visibilities.each do |v|
            unless (match = VISIBILITY_PATTERN.match(v))
              raise ArgumentError, "Syntax error in visibility rule #{v.inspect}"
            end

            rule = SitemapBuilder.factory.create_visibility_rule
            rule.item = match["item"]
            rule.condition = match["condition"]
            rule.sign = match["sign"]
            rule.state = match["state"]
            widget.visibility.add(rule)
          end

          widget
        end

        # @!visibility private
        def inspect
          s = +"#<OpenHAB::DSL::Sitemaps::#{@type.capitalize}Builder "
          s << (instance_variables - [:@children]).map do |iv|
            "#{iv}=#{instance_variable_get(iv).inspect}"
          end.join(" ")
          s << ">"
          s.freeze
        end

        private

        def add_color(widget_color, colors)
          colors.each do |c|
            unless (match = COLOR_PATTERN.match(c))
              raise ArgumentError, "Syntax error in color rule #{c.inspect}"
            end

            rule = SitemapBuilder.factory.create_color_array
            rule.item = match["item"]
            rule.condition = match["condition"]
            rule.sign = match["sign"]
            rule.state = match["state"]
            rule.arg = match["arg"]
            widget_color.add(color)
          end
        end
      end

      # Builds a `Switch` element
      # @see https://www.openhab.org/docs/ui/sitemaps.html#element-type-switch
      # @see org.openhab.core.model.sitemap.sitemap.Switch
      class SwitchBuilder < WidgetBuilder
        # Mappings from command to label
        #
        # Keys can be any {Core::Types::Command command}, values are strings.
        # If an array is given, the same value is used for both command and label.
        # @return [Hash, Array, nil]
        # @see https://www.openhab.org/docs/ui/sitemaps.html#mappings
        attr_accessor :mappings

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, mappings: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param mappings [Hash, Array, nil] Mappings from command to label (see {SwitchBuilder#mappings})
        # @!visibility private
        def initialize(type, mappings: nil, **kwargs)
          super(type, **kwargs)

          @mappings = mappings
        end

        # @!visibility private
        def build
          widget = super
          mappings&.each do |cmd, label|
            mapping = SitemapBuilder.factory.create_mapping
            mapping.cmd = cmd.to_s
            mapping.label = label&.to_s || cmd.to_s
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
        # @!method initialize(item: nil, label: nil, icon: nil, range: nil, step: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param range [Range, nil] Allowed range of the value (see {SetpointBuilder#range})
        # @param step [Numeric,nil] How far the value will change with each button press (see {SetpointBuilder#step})
        # @!visibility private
        def initialize(type, range: nil, step: nil, **kwargs)
          super(type, **kwargs)

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

        # (see SetpointBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, range: nil, step: nil, switch: nil, frequency: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param switch [true, false, nil]
        #   A short press on the item toggles the item on or off (see {SliderBuilder#switch=})
        # @param frequency [Numeric, nil]
        #   How often to send requests (in seconds) (see {SliderBuilder#frequency})
        # @!visibility private
        def initialize(type, switch: nil, frequency: nil, **kwargs)
          super(type, **kwargs)

          @switch = switch
          @frequency = frequency
        end

        # (see #switch=)
        def switch?
          @switch_enabled
        end

        # @!visibility private
        def build
          widget = super
          widget.switch_enabled = switch?
          widget.send_frequency = (frequency * 1000).to_i if frequency
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
        # @!method initialize(item: nil, label: nil, icon: nil, url: nil, encoding: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param [String, nil] url (see {VideoBuilder#url})
        # @param [:mjpeg, :hls, nil] encoding (see {VideoBuilder#encoding})
        # @!visibility private
        def initialize(type, url: nil, encoding: nil, **kwargs)
          super(type, **kwargs)

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
        # @see https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/text/DecimalFormat.html DecimalFormat
        attr_accessor :y_axis_pattern

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, service: nil, refresh: nil, period: nil, legend: nil, group: nil, y_axis_pattern: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
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
                       service: nil,
                       refresh: nil,
                       period: nil,
                       legend: nil,
                       group: nil,
                       y_axis_pattern: nil,
                       **kwargs)
          super(type, **kwargs)

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
        # @!method initialize(item: nil, label: nil, icon: nil, height: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param height [Integer] The number of element rows to fill (see {DefaultBuilder#height})
        # @!visibility private
        def initialize(type, height: nil, **kwargs)
          super(type, **kwargs)

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
        # @!method initialize(item: nil, label: nil, icon: nil, url: nil, height: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param url [String, nil] (see {WebviewBuilder#url})
        # @!visibility private
        def initialize(type, url: nil, **kwargs)
          super(type, **kwargs)

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
        # @!method initialize(item: nil, label: nil, icon: nil, frequency: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param frequency [Numeric, nil] How often to send requests (see {ColorpickerBuilder#frequency})
        # @!visibility private
        def initialize(type, frequency: nil, **kwargs)
          super(type, **kwargs)

          @frequency = frequency
        end

        # @!visibility private
        def build
          widget = super
          widget.frequency = (frequency * 1000).to_i if frequency
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
        # @!method initialize(item: nil, label: nil, icon: nil, hint: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param [:text, :number, :date, :time, :datetime, nil] hint
        #   Gives a hint to the user interface to use a widget adapted to a specific use (see {InputBuilder#hint})
        # @!visibility private
        def initialize(type, hint: nil, **kwargs)
          super(type, **kwargs)

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

      # Parent class for builders of widgets that can contain other widgets.
      # @see org.openhab.core.model.sitemap.sitemap.LinkableWidget
      class LinkableWidgetBuilder < WidgetBuilder
        include Core::EntityLookup

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
        #              range: nil,
        #              step: nil,
        #              switch: nil,
        #              frequency: nil,
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
        #             hint: nil,
        #             label_color: nil,
        #             value_color: nil,
        #             icon_color: nil,
        #             visibility: nil)
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
        #                   frequency: nil,
        #                   label_color: nil,
        #                   value_color: nil,
        #                   icon_color: nil,
        #                   visibility: nil)
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
           setpoint
           colorpicker
           default].each do |method|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method}(*args, **kwargs, &block)                         # def frame(*args, **kwargs, &block)
              widget = #{method.capitalize}Builder.new(#{method.inspect},  #   widget = FrameBuilder.new(:frame,
                                                       *args,              #                             *args,
                                                       **kwargs)           #                             **kwargs)
              widget.instance_eval_with_dummy_items(&block) if block       #   widget.instance_eval_with_dummy_items(&block) if block
              children << widget                                           #   children << widget
              widget                                                       #   widget
            end                                                            # end
          RUBY
        end

        # (see WidgetBuilder#initialize)
        # @!method initialize(item: nil, label: nil, icon: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @!visibility private
        def initialize(*, **)
          super

          @children = []
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
        # @!method initialize(item: nil, label: nil, icon: nil, url: nil, refresh: nil, label_color: nil, value_color: nil, icon_color: nil, visibility: nil)
        # @param url [String, nil] The URL for the image (see {ImageBuilder#url})
        # @param refresh [Numeric, nil] How often to refresh the image (see {ImageBuilder#refresh})
        # @!visibility private
        def initialize(type, url: nil, refresh: nil, **kwargs)
          super(type, **kwargs)

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
        def initialize(name, label = nil, icon: nil)
          super(:sitemap, label: label, icon: icon)

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
