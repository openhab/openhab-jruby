# frozen_string_literal: true

module OpenHAB
  module Core
    #
    # Contains sitemap related classes.
    #
    module Sitemaps
      #
      # Provides sitemaps created in Ruby to openHAB
      #
      class Provider < Core::Provider
        class << self
          #
          # The Sitemap registry
          #
          # @return [org.openhab.core.sitemap.registry.SitemapRegistry, nil]
          #
          # @since 5.2.0
          #
          def registry
            return @registry if instance_variable_defined?(:@registry)

            @registry = OSGi.service("org.openhab.core.sitemap.registry.SitemapRegistry")
          end

          # @!visibility private
          def factory
            # @deprecated OH 5.2: remove the non-registry branch when dropping OH 5.1
            @factory ||= if registry
                           OSGi.service("org.openhab.core.sitemap.registry.SitemapFactory")
                         else
                           org.openhab.core.model.sitemap.sitemap.SitemapFactory.eINSTANCE
                         end
          end
        end

        # @deprecated OH 5.2: remove the non-registry branch when dropping OH 5.1
        if registry
          require_relative "linkable_widget"
          require_relative "sitemap"
          require_relative "widget"

          include org.openhab.core.sitemap.registry.SitemapProvider
        else
          require_relative "model"

          include org.openhab.core.model.sitemap.SitemapProvider

          SUFFIX = ".sitemap"
          private_constant :SUFFIX

          # rubocop:disable Naming/MethodName

          # @!visibility private
          def addModelChangeListener(listener)
            @listeners.add(listener)
          end

          # @!visibility private
          def removeModelChangeListener(listener)
            @listeners.remove(listener)
          end
          # rubocop:enable Naming/MethodName

          def unregister
            clear
            @registration.unregister
          end

          # @!visibility private
          def update(sitemap)
            if sitemap.respond_to?(:to_str)
              sitemap = get(sitemap).tap do |obj|
                raise ArgumentError, "Sitemap #{sitemap} not found" unless obj
              end
            end
            super
          end

          # @!visibility private
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

          public

        end

        # rubocop:disable Naming/MethodName
        alias_method :getSitemap, :get

        # @!visibility private
        def getSitemapNames
          @elements.key_set
        end
        # rubocop:enable Naming/MethodName

        private

        # @deprecated OH 5.2: Remove this entire method when dropping OH 5.1
        # I can't put this in Model::Provider#initialize, due to https://github.com/jruby/jruby/issues/9321
        def extra_initialize
          return if self.class.registry

          @listeners = java.util.concurrent.CopyOnWriteArraySet.new
          @registration = OSGi.register_service(self, org.openhab.core.model.sitemap.SitemapProvider)
        end
      end
    end
  end
end

# @deprecated OH 5.2: Remove require when dropping OH 5.1
require_relative "compatibility"
