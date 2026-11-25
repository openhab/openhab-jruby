# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  module Thermos
    class ProcessTitleUpdater
      SECOND = 1
      MINUTE = 60
      HOUR   = 60 * 60

      def self.run(&)
        updater = new(&)

        Thermos.failsafe_thread do
          $0 = updater.value
          loop { $0 = updater.next }
        end
      end

      attr_reader :block

      def initialize(start = Time.now, &block)
        @start = start
        @block = block
      end

      def interval
        distance = Time.now - @start

        if distance < MINUTE
          SECOND
        elsif distance < HOUR
          MINUTE
        else
          HOUR
        end
      end

      def next
        sleep interval
        value
      end

      def value
        block.call(distance_in_words)
      end

      def distance_in_words(now = Time.now)
        distance = now - @start

        if distance < MINUTE
          pluralize(distance, "sec")
        elsif distance < HOUR
          pluralize(distance / MINUTE, "min")
        else
          pluralize(distance / HOUR, "hour")
        end
      end

      private

      def pluralize(amount, unit)
        "#{amount.to_i} #{(amount.to_i == 1) ? unit : "#{unit}s"}"
      end
    end
  end
end
