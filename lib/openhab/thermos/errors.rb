# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  module Thermos
    class ClientError < StandardError; end

    class UnknownProject < StandardError
      attr_reader :current_dir

      def initialize(current_dir)
        super()

        @current_dir = current_dir
      end

      def message
        "thermos was unable to locate the root of your project. There was no Gemfile " \
          "present in the current directory (#{current_dir}) or any of the parent " \
          "directories."
      end
    end

    class CommandNotFound < ClientError
    end
  end
end
