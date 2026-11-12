# frozen_string_literal: true

module OpenHAB
  module Core
    # Contains core communication related modules
    module IO
      # Contains modules for initiating communications via generic protocols
      module Transport
        # Access to openHAB's local and remote serial port providers.
        module Serial
          # @return [SerialPortManager] The serial port manager.
          def self.manager
            @manager ||= OSGi.service("org.openhab.core.io.transport.serial.SerialPortManager")
          end
        end
      end
    end
  end
end

require_relative "serial/serial_port_manager"
require_relative "serial/serial_port"
