# frozen_string_literal: true

module OpenHAB
  #
  # OSGi services interface
  #
  module OSGi
    class << self
      #
      # @param name [String] The service name
      # @param filter [String] Filter for service names. See https://docs.osgi.org/javadoc/r4v43/core/org/osgi/framework/Filter.html
      #
      # @return [Object]
      #
      def service(name, filter: nil)
        services(name, filter: filter).first
      end

      #
      # @param name [String] The service name
      # @param filter [String] Filter for service names. See https://docs.osgi.org/javadoc/r4v43/core/org/osgi/framework/Filter.html
      #
      # @return [Array<Object>] An array of services
      #
      def services(name, filter: nil)
        (bundle_context.get_service_references(name, filter) || []).map do |reference|
          logger.trace "OSGi service found for '#{name}' using OSGi Service Reference #{reference}"
          bundle_context.get_service(reference)
        end
      end

      #
      # Register a new service instance with OSGi
      #
      # @param [Object] instance The service instance
      # @param [Module] interfaces The interfaces to register this service for.
      #   If not provided, it will default to all Java interfaces the instance
      #   implements.
      # @param [Hash] properties The service registration properties.
      # @return [org.osgi.framework.ServiceRegistration]
      #
      def register_service(instance, *interfaces, **properties)
        if interfaces.empty?
          interfaces = instance.class.ancestors.select { |k| k.respond_to?(:java_class) && k.java_class&.interface? }
        end

        bundle = org.osgi.framework.FrameworkUtil.get_bundle(interfaces.first)
        bundle.bundle_context.register_service(
          interfaces.map(&:java_class).map(&:name).to_java(java.lang.String),
          instance,
          java.util.Hashtable.new(properties)
        )
      end

      # @!attribute [r] bundle_context
      # @return [org.osgi.framework.BundleContext] OSGi bundle context for ScriptExtension Class
      def bundle_context
        @bundle_context ||= bundle.bundle_context
      end

      # @!attribute [r] bundle
      # @return [org.osgi.framework.Bundle] The OSGi Bundle for ScriptExtension Class
      def bundle
        @bundle ||= org.osgi.framework.FrameworkUtil.getBundle($scriptExtension.class)
      end
    end
  end
end
