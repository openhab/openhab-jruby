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
          require_relative "sitemap"

          include org.openhab.core.sitemap.registry.SitemapProvider
        else
          require_relative "model"

          prepend Model::Provider
        end

        alias_method :getSitemap, :get # rubocop:disable Naming/MethodName

        # rubocop:disable Naming/MethodName
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
