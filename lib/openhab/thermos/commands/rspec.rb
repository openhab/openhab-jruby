# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

module OpenHAB
  module Thermos
    module Commands
      class RSpec
        def exec_name
          "rspec"
        end

        def gem_name
          "rspec-core"
        end

        def setup
          require "rspec/core"
          ::RSpec::Core::ConfigurationOptions.new([]).configure(::RSpec.configuration)
          raise "RSpec setup failed while loading its configured requires" if ::RSpec.world.wants_to_quit
        end

        def call
          require "rspec/core"
          load Gem.bin_path(gem_name, exec_name)
        end
      end

      Thermos.register_command "rspec", RSpec.new
    end
  end
end
