# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require "pathname"
require_relative "../thermos"
require_relative "errors"

module OpenHAB
  module Thermos
    IGNORE_SIGNALS = %w[INT].freeze
    ORIGINAL_ENV = ENV.to_h.freeze
    @connect_timeout = 5
    @boot_timeout = 20

    class << self
      attr_accessor :connect_timeout, :boot_timeout
      attr_writer :quiet

      def gemfile
        require "bundler"
        Bundler.default_gemfile
      rescue Bundler::GemfileNotFound
        raise UnknownProject, Dir.pwd
      end

      def gemfile_lock
        (gemfile.basename.to_s == "gems.rb") ? gemfile.sub_ext(".locked") : gemfile.sub_ext(".lock")
      end

      def spawn_on_env = (@spawn_on_env ||= [])
      def reset_on_env = (@reset_on_env ||= [])
      def verify_environment = project_root_path
      def project_root_path = gemfile.dirname.expand_path
      def quiet = @quiet || ENV.key?("THERMOS_QUIET")

      def failsafe_thread(&)
        Thread.new do
          yield
        rescue => e
          warn e.full_message
        end
      end
    end

    self.quiet = false
  end
end
