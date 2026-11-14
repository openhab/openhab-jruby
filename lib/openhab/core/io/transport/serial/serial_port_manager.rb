# frozen_string_literal: true

module OpenHAB
  module Core
    module IO
      module Transport
        module Serial
          java_import org.openhab.core.io.transport.serial.SerialPortManager

          # Finds and opens ports through openHAB's serial infrastructure.
          module SerialPortManager
            include Enumerable

            # Enumerates discovered port names. Known names can also be opened even
            # when their provider does not support discovery.
            # @yieldparam [String] name
            # @return [Enumerator, self]
            def each
              return enum_for(__method__) unless block_given?

              identifiers = self.identifiers
              begin
                identifiers.for_each { |identifier| yield identifier.name }
              ensure
                identifiers.close
              end
              self
            end

            # @return [Array<String>] Discovered port names.
            def names
              to_a
            end

            # @param [String] name
            # @return [Boolean] Whether the port is owned (including by this process).
            def owned?(name)
              get_identifier(name)&.currently_owned?
            end

            # @param [String] name
            # @return [String, nil] The port's reported owner.
            def current_owner(name)
              get_identifier(name)&.current_owner
            end
          end
        end
      end
    end
  end
end
