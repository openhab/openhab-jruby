# frozen_string_literal: true

# @deprecated OH 5.2: Remove entire file when dropping OH 5.1
# Don't forget to remove the reference to it in .yardopts
return if OpenHAB::Core::Sitemaps::Provider.registry

module OpenHAB
  module Core
    module Sitemaps
      # Adds compatibility shims for the old Xtext based Sitemap model to the newer registry style
      # @!visibility private
      module Model
        org.openhab.core.model.sitemap.sitemap.impl.SitemapImpl.alias_method :uid, :name
        org.openhab.core.model.sitemap.sitemap.impl.SitemapImpl.alias_method :widgets, :children

        org.openhab.core.model.sitemap.sitemap.impl.LinkableWidgetImpl.alias_method :widgets, :children

        module Rule
          org.openhab.core.model.sitemap.sitemap.impl.ColorArrayImpl.include(self)
          org.openhab.core.model.sitemap.sitemap.impl.IconRuleImpl.include(self)

          def argument = arg

          def argument=(value)
            self.arg = value
          end
        end

        module Widget
          org.openhab.core.model.sitemap.sitemap.impl.WidgetImpl.prepend(self)

          def icon
            static_icon || super
          end

          def icon=(value)
            if instance_variable_defined?(:@static_icon) && @static_icon
              self.static_icon = value
              return
            end
            super
          end

          def static_icon=(value)
            # Disable "instance vars on non-persistent Java type"
            original_verbose = $VERBOSE
            $VERBOSE = nil
            if value == true
              @static_icon = true
              return
            end

            super
          ensure
            $VERBOSE = original_verbose
          end
        end

        module Condition
          org.openhab.core.model.sitemap.sitemap.impl.ConditionImpl.include(self)

          def value = "#{sign}#{state}"
        end

        module Provider
          def self.prepended(klass)
            klass.include org.openhab.core.model.sitemap.SitemapProvider
          end

          SUFFIX = ".sitemap"
          private_constant :SUFFIX

          def getSitemap = get # rubocop:disable Naming/MethodName

          # rubocop:disable Naming/MethodName
          def getSitemapNames
            @elements.key_set
          end

          def addModelChangeListener(listener)
            @listeners.add(listener)
          end

          def removeModelChangeListener(listener)
            @listeners.remove(listener)
          end
          # rubocop:enable Naming/MethodName

          def unregister
            clear
            @registration.unregister
          end

          def update(sitemap)
            if sitemap.respond_to?(:to_str)
              sitemap = get(sitemap).tap do |obj|
                raise ArgumentError, "Sitemap #{sitemap} not found" unless obj
              end
            end
            super
          end

          def remove(sitemap)
            sitemap = sitemap.uid if sitemap.respond_to?(:uid)
            super
          end

          private

          def notify_listeners_about_added_element(element)
            model_name = "#{element.name}#{SUFFIX}"
            @listeners.each do |listener|
              listener.modelChanged(model_name, org.openhab.core.model.core.EventType::ADDED)
              listener.modelChanged(model_name, org.openhab.core.model.core.EventType::MODIFIED)
            end
          end

          def notify_listeners_about_removed_element(element)
            model_name = "#{element.name}#{SUFFIX}"
            @listeners.each { |listener| listener.modelChanged(model_name, org.openhab.core.model.core.EventType::REMOVED) }
          end

          def notify_listeners_about_updated_element(_old_element, element)
            model_name = "#{element.name}#{SUFFIX}"
            @listeners.each { |listener| listener.modelChanged(model_name, org.openhab.core.model.core.EventType::MODIFIED) }
          end
        end
      end
    end
  end
end
