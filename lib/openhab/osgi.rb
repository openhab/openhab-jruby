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
        services(name, filter:).first
      end

      #
      # @param name [String] The service name
      # @param filter [String] Filter for service names. See https://docs.osgi.org/javadoc/r4v43/core/org/osgi/framework/Filter.html
      #
      # @return [Array<Object>] An array of services
      #
      def services(name, filter: nil)
        (bundle_context.get_service_references(name, filter) || []).map do |reference|
          logger.trace { "OSGi service found for '#{name}' using OSGi Service Reference #{reference}" }
          bundle_context.get_service(reference)
        end
      end

      #
      # Register a new service instance with OSGi
      #
      # @param [Object] instance The service instance
      # @param [Module, String] interfaces The interfaces to register this service for.
      #   If not provided, it will default to all Java interfaces the instance
      #   implements.
      # @param [org.osgi.framework.Bundle, nil] bundle The bundle to register
      #   the service from. If not provided, it will default to the bundle of the first
      #   interface.
      # @param [Hash] properties The service registration properties.
      # @return [org.osgi.framework.ServiceRegistration]
      #
      def register_service(instance, *interfaces, bundle: nil, **properties)
        if interfaces.empty?
          interfaces = instance.class.ancestors.select { |k| k.respond_to?(:java_class) && k.java_class&.interface? }
        end

        bundle_class = interfaces.first.is_a?(Module) ? interfaces.first : instance
        bundle ||= org.osgi.framework.FrameworkUtil.get_bundle(bundle_class.java_class)
        interfaces.map! { |i| i.is_a?(String) ? i : i.java_class.name }
        bundle.bundle_context.register_service(
          interfaces.to_java(java.lang.String),
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
        @bundle ||= org.osgi.framework.FrameworkUtil.getBundle($scriptExtension.java_class)
      end

      # @!visibility private
      SCR_NAMESPACE = "http://www.osgi.org/xmlns/scr/v1.4.0"
      private_constant :SCR_NAMESPACE

      # @!visibility private
      def service_component_classes(bundle)
        require "nokogiri"

        component_paths = bundle.headers.get(
          org.osgi.service.component.ComponentConstants::SERVICE_COMPONENT
        )&.split(",") || []
        component_paths.filter_map do |path|
          stream = bundle.get_entry(path).open_stream
          xml = Nokogiri::XML(String.from_java_bytes(stream.read_all_bytes))

          class_name = xml.at_xpath("scr:component/implementation", scr: SCR_NAMESPACE)&.[]("class")
          next unless class_name

          services = xml.xpath("scr:component/service/provide", scr: SCR_NAMESPACE).map { |p| p["interface"] }

          [bundle.load_class(class_name), services]
        ensure
          stream&.close
        end.to_h
      end
    end
  end
end
