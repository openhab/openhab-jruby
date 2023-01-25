# frozen_string_literal: true

module OpenHAB
  # Contains classes and modules that wrap actual openHAB objects
  module Core
    # The openHAB Version. >= 3.4.0 is required.
    # @return [String]
    VERSION = org.openhab.core.OpenHAB.version.freeze

    unless Gem::Version.new(VERSION) >= Gem::Version.new("3.4.0")
      raise "`openhab-jrubyscripting` requires openHAB >= 3.4.0"
    end

    # @return [Integer] Number of seconds to wait between checks for automation manager
    CHECK_DELAY = 10
    private_constant :CHECK_DELAY
    class << self
      #
      # Wait until openHAB engine ready to process
      #
      # @return [void]
      #
      # @!visibility private
      def wait_till_openhab_ready
        logger.trace("Checking readiness of openHAB")
        until automation_manager
          logger.trace("Automation manager not loaded, checking again in #{CHECK_DELAY} seconds.")
          sleep CHECK_DELAY
        end
        logger.trace "Automation manager instantiated, openHAB ready for rule processing."
      end

      #
      # @!attribute [r] config_folder
      # @return [Pathname] The configuration folder path.
      #
      def config_folder
        Pathname.new(org.openhab.core.OpenHAB.config_folder)
      end

      #
      # @!attribute [r] automation_manager
      # @return [org.openhab.core.automation.module.script.rulesupport.shared.ScriptedAutomationManager]
      #   The openHAB Automation manager.
      #
      def automation_manager
        $se.get("automationManager")
      end

      #
      # Imports a specific script extension preset into the global namespace
      #
      # @param [String] preset
      # @return [void]
      #
      def import_preset(preset)
        import_scope_values($se.import_preset(preset))
      end

      #
      # Imports all default script extension presets into the global namespace
      #
      # @!visibility private
      # @return [void]
      #
      def import_default_presets
        $se.default_presets.each { |preset| import_preset(preset) }
      end

      #
      # Imports concrete scope values into the global namespace
      #
      # @param [java.util.Map<String, Object>] scope_values
      # @!visibility private
      # @return [void]
      #
      def import_scope_values(scope_values)
        scope_values.for_each do |key, value|
          # convert Java classes to Ruby classes
          value = value.ruby_class if value.is_a?(java.lang.Class) # rubocop:disable Lint/UselessAssignment
          # variables are globals; constants go into the global namespace
          key = case key[0]
                when "a".."z" then "$#{key}"
                when "A".."Z" then "::#{key}"
                end
          eval("#{key} = value unless defined?(#{key})", nil, __FILE__, __LINE__) # rubocop:disable Security/Eval
        end
      end
    end

    import_default_presets unless defined?($ir)
  end
end

# several classes rely on this, so force it to load earlier
require_relative "core/provider"

Dir[File.expand_path("core/**/*.rb", __dir__)].sort.each do |f|
  require f
end
