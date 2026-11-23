# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

require_relative "command"

module OpenHAB
  module Thermos
    module Client
      # Installs the project launcher and adds it to Ruby binstubs.
      # @!visibility private
      class Binstub < Command
        SHEBANG = /\#!.*\n(\#.*\n)*/

        # If loading the bin/thermos file works, it'll run Thermos which will
        # eventually call Kernel.exit. This means that in the client process
        # we will never execute the lines after this block. But if the Thermos
        # client is not invoked for whatever reason, then the Kernel.exit won't
        # happen, and so we'll fall back to the lines after this block, which
        # should cause the regular version of the command to run.
        LOADER = <<~RUBY
          load File.expand_path("thermos", __dir__)
        RUBY

        LAUNCHER = <<~RUBY
          #!/usr/bin/env ruby
          # frozen_string_literal: true

          # This file loads Thermos without loading other gems in the Gemfile in order to be fast.
          # It gets overwritten when you run the `thermos binstub` command.

          unless defined?(OpenHAB::Thermos::Client) || (defined?(OpenHAB::Thermos.context) && OpenHAB::Thermos.context)
            require "bundler"

            spec = Bundler.locked_gems.specs.find { |candidate| candidate.name == "openhab-scripting" }
            if spec
              Gem.use_paths Gem.dir, Bundler.bundle_path.to_s, *Gem.path
              installed = Gem::Specification.find_all_by_name("openhab-scripting", spec.version.to_s).first
              library = if installed
                          File.join(installed.full_gem_path, "lib")
                        elsif spec.source.respond_to?(:path)
                          File.expand_path("lib", spec.source.path.expand_path(Bundler.root))
                        end
              $LOAD_PATH.unshift(library) if library
            end
            require "openhab/thermos/binstub"
          end
        RUBY

        BINSTUB_VARIATIONS = Regexp.union([
          LOADER
        ].map { |binstub| /#{Regexp.escape(binstub).gsub("'", "['\"]")}/ })

        class Item
          attr_reader :command, :existing

          def initialize(command)
            @command = command

            @existing = command.binstub.read if command.binstub.exist?
          end

          def status(text, stream = $stdout)
            stream.puts "* #{command.binstub_name}: #{text}"
          end

          def add
            if existing
              if existing.include?(LOADER)
                status "thermos already present"
              else
                head, shebang, tail = existing.partition(SHEBANG)

                if shebang.include?("ruby")
                  unless command.binstub.exist?
                    FileUtils.touch command.binstub
                    command.binstub.chmod 0o755
                  end

                  File.write(command.binstub, "#{head}#{shebang}#{LOADER}#{tail}")
                  status "thermos inserted"
                else
                  status "doesn't appear to be ruby, so cannot use thermos", $stderr
                  exit 1
                end
              end
            else
              generate
              status "generated with thermos"
            end
          end

          def generate(fallback = nil)
            fallback ||= "require 'bundler/setup'\n" \
                         "load Gem.bin_path(#{command.gem_name.dump}, #{command.exec_name.dump})\n"

            File.write(command.binstub, "#!/usr/bin/env ruby\n#{LOADER}#{fallback}")
            command.binstub.chmod 0o755
          end

          def remove
            return unless existing

            File.write(command.binstub, existing.sub(BINSTUB_VARIATIONS, ""))
            status "thermos removed"
          end
        end

        attr_reader :bindir, :items

        class << self
          def description
            "Generate thermos based binstubs. " \
              "Use --all to generate a binstub for all known commands. " \
              "Use --remove to revert."
          end

          def call(args)
            require_relative "../commands"
            super
          end
        end

        def initialize(args)
          super

          @bindir = env.project_root.join("bin")
          @all    = false
          @mode   = :add
          @items  = args.drop(1)
                        .map { |name| find_commands name }
                        .flatten.uniq
                        .map { |command| Item.new(command) }
        end

        def find_commands(name)
          case name
          when "--all"
            @all = true
            Thermos.commands.values
          when "--remove"
            @mode = :remove
            []
          else
            if (command = Thermos.commands[name])
              [command]
            else
              warn "The '#{name}' command is not known to thermos."
              exit 1
            end
          end
        end

        def call
          case @mode
          when :add
            bindir.mkdir unless bindir.exist?

            if thermos_binstub.exist? && !thermos_binstub.read.include?("openhab/thermos/binstub")
              raise ClientError, "#{thermos_binstub} already exists and is not a thermos binstub"
            end

            File.write(thermos_binstub, LAUNCHER)
            thermos_binstub.chmod 0o755

            items.each(&:add)
          when :remove
            thermos_binstub.delete if @all && thermos_binstub.exist?
            items.each(&:remove)
          else
            raise ArgumentError
          end
        end

        def thermos_binstub
          bindir.join("thermos")
        end
      end
    end
  end
end
