# frozen_string_literal: true

module OpenHAB
  # Contains classes and modules that wrap actual openHAB objects
  module Core
    # The openHAB Version. >= 4.1 is required.
    # @return [String]
    VERSION = org.openhab.core.OpenHAB.version.freeze

    # @!visibility private
    V4_1 = Gem::Version.new("4.1.0").freeze
    # @!visibility private
    V4_2 = Gem::Version.new("4.2.0").freeze
    # @!visibility private
    V4_3 = Gem::Version.new("4.3.0").freeze
    # @!visibility private
    V5_0 = Gem::Version.new("5.0.0").freeze
    # @!visibility private
    V5_1 = Gem::Version.new("5.1.0").freeze

    # @return [Gem::Version] Returns the current openHAB version as a Gem::Version object
    #   Note, this strips off snapshots, milestones and RC versions and returns the release version.
    # @!visibility private
    def self.version
      @version ||= Gem::Version.new(VERSION).release.freeze
    end

    #
    # Returns the full version of openHAB
    #
    # The {version} method returns the release version, stripping off any
    # additional qualifiers such as M1, or snapshots.
    # This method returns the full version string, including the qualifiers.
    #
    # @return [Gem::Version] Returns the full version of openHAB
    #
    # @!visibility private
    #
    def self.full_version
      @full_version ||= Gem::Version.new(VERSION).freeze
    end

    raise "`openhab-scripting` requires openHAB >= 4.1.0" unless version >= V4_1

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
          logger.trace { "Automation manager not loaded, checking again in #{CHECK_DELAY} seconds." }
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
      # @!attribute [r] user_data_folder
      # @return [Pathname] The userdata folder path.
      #
      def user_data_folder
        Pathname.new(org.openhab.core.OpenHAB.user_data_folder)
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

      #
      # Returns a hash of global context variable `$ctx` injected into UI based scripts.
      #
      # The keys in $ctx are prefixed with the trigger module id.
      # This method strips them off and symbolizes them so they are accessible without the module id prefix.
      #
      # @!visibility private
      # @return [Hash<Symbol, Object>, nil]
      #
      def ui_context
        # $ctx is a java.util.HashMap and its #to_h doesn't take a block like Ruby's
        # We cannot memoize this because the context can change between calls
        $ctx&.to_hash&.to_h do |key, value|
          [
            key.split(".", 2).last.to_sym,
            case value
            when Items::Item then Items::Proxy.new(value)
            when Things::Thing then Things::Proxy.new(value)
            else value
            end
          ]
        end.freeze
      end
    end

    import_default_presets unless defined?($ir)
  end
end

# several classes rely on this, so force it to load earlier
require_relative "core/provider"

Dir[File.expand_path("core/**/*.rb", __dir__)].each do |f|
  # metadata is autoloaded
  require f unless f.include?("/metadata/")
end
