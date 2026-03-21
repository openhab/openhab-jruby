# frozen_string_literal: true

module OpenHAB
  module Core
    module Sitemaps
      #
      # Compatibility helpers for old model-backed sitemaps and the new core sitemap registry.
      #
      # @deprecated OH 5.2: Remove entire module when dropping OH 5.1, collapsing calls to match the registry branch
      # Don't forget to remove the reference to it in .yardopts
      # @!visibility private
      module Compatibility
        class << self
          def factory
            Provider.factory
          end

          if Provider.registry
            def supported_widget_type?(type)
              return true if type == :sitemap

              factory.get_supported_widget_types.include?(camelize(type))
            end

            def create_sitemap(name)
              factory.create_sitemap(name)
            end

            def create_widget(type, parent = nil)
              parent ? factory.create_widget(camelize(type), parent) : factory.create_widget(camelize(type))
            end

            def create_rule(_type)
              factory.create_rule
            end

            def set_condition(condition, sign:, state:)
              condition.value = "#{sign}#{state}"
            end
          else
            def supported_widget_type?(type)
              factory.respond_to?(:"create_#{type}")
            end

            def create_sitemap(name)
              factory.create_sitemap.tap { |sitemap| sitemap.name = name }
            end

            def create_widget(type, _parent = nil)
              factory.public_send(:"create_#{type}")
            end

            def create_rule(type)
              case type
              when :visibility then factory.create_visibility_rule
              when :icon then factory.create_icon_rule
              when :color then factory.create_color_array
              end
            end

            def set_condition(condition, sign:, state:)
              condition.sign = sign
              condition.state = state
            end
          end

          private

          def camelize(type)
            type.to_s.split("_").map(&:capitalize).join
          end
        end
      end
    end
  end
end
