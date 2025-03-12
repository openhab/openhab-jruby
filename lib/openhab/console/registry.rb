# frozen_string_literal: true

# This provides the list for the `jrubyscripting console --list` command
module OpenHAB
  module Console
    # The keys are the names of the file to be required
    REGISTRY = {
      jline: "A basic JRuby REPL",
      irb: "IRB console"
    }.freeze
  end
end
