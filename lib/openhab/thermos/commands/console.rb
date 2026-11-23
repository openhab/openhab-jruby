# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  module Thermos
    module Commands
      class Console
        # IRB normally reopens the descriptors, creating additional owners of the
        # server's streams. Reuse the engine's non-owning views instead.
        module StdioInputMethod
          def initialize
            @line_no = 0
            @line = []
            @stdin = $stdin
            @stdout = $stdout
          end
        end
        private_constant :StdioInputMethod

        def description = "Start an IRB console with openHAB rules and transformations loaded."
        def exec_name = "irb"
        def gem_name = "irb"

        def setup
          Thermos.command("rspec").setup
        end

        def call
          require "irb"
          ::IRB::StdioInputMethod.prepend(StdioInputMethod)
          thread = Thread.current
          OpenHAB::Thermos.context["on_interrupt"] = ->(signal) { interrupt(thread, signal) }
          Thermos.command("rspec").setup
          OpenHAB::RSpec::Helpers.autorequires unless OpenHAB::RSpec::Configuration.private_confdir
          OpenHAB::RSpec::Helpers.load_transforms
          OpenHAB::RSpec::Helpers.load_rules
          ::IRB::TOPLEVEL_BINDING.receiver.extend(OpenHAB::DSL)
          ::IRB.start(__FILE__)
        end

        private

        def interrupt(thread, signal)
          return thread.raise(SystemExit.new(128 + Signal.list.fetch(signal))) unless signal == "INT"

          context = ::IRB.conf[:MAIN_CONTEXT]
          return thread.raise(Interrupt) unless context
          return thread.raise(SystemExit.new(130)) unless context.ignore_sigint?

          context.irb.signal_handle
        rescue ::IRB::RubyLex::TerminateLineInput => e
          thread.raise(e)
        end
      end

      Thermos.register_command "console", Console.new
    end
  end
end
