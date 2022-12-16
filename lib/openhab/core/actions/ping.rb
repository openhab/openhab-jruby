# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      # @see org.openhab.core.model.script.actions.Ping
      class Ping
        class << self
          #
          # Checks the vitality of host.
          #
          # If port is `nil`, a regular ping is issued. If other ports are
          # specified we try to open a new Socket with the given timeout.
          #
          # @param [String] host
          # @param [int, nil] port
          # @param [Duration, Integer, nil] timeout Connect timeout (in milliseconds, if given as an Integer)
          # @return [true, false]
          #
          def check_vitality(host, port = nil, timeout = nil)
            port ||= 0
            timeout ||= 0
            timeout = timeout.to_millis if timeout.is_a?(Duration)
            checkVitality(host, port, timeout)
          end
        end
      end
    end
  end
end
