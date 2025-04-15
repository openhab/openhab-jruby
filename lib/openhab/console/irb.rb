# frozen_string_literal: true

require "openhab/console/stdio"

require "irb"

raise "IRB Version 1.14 or later is required." unless Gem::Version.new(IRB::VERSION) >= Gem::Version.new("1.14")

module OpenHAB
  # @!visibility private
  module Console
    module IRB
      class Exit < Exception; end # rubocop:disable Lint/InheritException

      module Irb
        # Define #exit instead of using Kernel#exit, to raise an error if we're not
        # on the main thread (i.e. in the signal handler)
        def exit
          raise Exit unless Thread.current == context.thread

          super
        end

        # Define #trap instead of using Kernel#trap, so that we register a signal handler against JLine.
        # It can also never be as effective, since it's an SSH session, not a true signal, and thus it
        # comes in as part of the input stream, and if we're not actively reading the input stream (cause
        # we're executing a blocking Ruby method), we won't see it to be able to interrupt the Ruby code.
        def trap(signal, handler = nil)
          jline_signal = org.jline.terminal.Terminal::Signal.const_get(signal.sub(/^SIG/, ""), false)
          return $terminal.handle(jline_signal, handler) if handler

          $terminal.handle(jline_signal) do
            yield
          rescue StandardError, Exit => e
            context.thread.raise e
          end
        end
      end
      ::IRB::Irb.include(Irb)

      module StdioInputMethod
        # make sure we use our replacement stdio streams, and not the
        # re-opened ones based on STDIN/STDOUT
        def initialize
          super

          @stdin = $stdin
          @stdout = $stdout
        end
      end
      ::IRB::StdioInputMethod.prepend(StdioInputMethod)
      [::IRB::ReadlineInputMethod, ::IRB::RelineInputMethod].each do |klass|
        klass.include(StdioInputMethod)
      end

      module ReadlineInputMethod
        def initialize
          super

          $terminal.echo_enabled = false
        end
      end
      ::IRB::ReadlineInputMethod.prepend(ReadlineInputMethod)

      module EntityCompletor
        VALID_ENTITY_PREFIXES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"

        def completion_candidates(_preposing, target, _postposing, bind:)
          return super unless defined?(OpenHAB::Core::EntityLookup)
          return super unless VALID_ENTITY_PREFIXES.include?(target[0])

          this = bind.eval("self")
          return super unless this.is_a?(OpenHAB::Core::EntityLookup)

          matching_items = OpenHAB::DSL.items.filter_map do |item|
            item.name if item.name.start_with?(target)
          end
          matching_things = OpenHAB::DSL.things.filter_map do |thing|
            id = thing.uid.to_s.tr(":", "_")
            id if id.start_with?(target)
          end
          matching_items | matching_things | super
        end
      end
      ::IRB::RegexpCompletor.prepend(EntityCompletor)
      ::IRB::TypeCompletor.prepend(EntityCompletor)
    end
  end
end

# disable Reline for now; it's not working
IRB.conf[:USE_MULTILINE] = false
# Uncomment to disable Readline and force StdioInputMethod
# IRB.conf[:USE_SINGLELINE] = false

# IRB uses Reline to find the window size initially, even if it's not
# using the Reline input method
Reline.input = $stdin
Reline.output = $stdout

begin
  IRB.start("karaf")
rescue OpenHAB::Console::IRB::Exit
  exit
end
