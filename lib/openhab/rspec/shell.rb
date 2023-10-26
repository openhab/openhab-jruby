# frozen_string_literal: true

module OpenHAB
  module RSpec
    # based on https://stackoverflow.com/questions/1197224/source-shell-script-into-environment-within-a-ruby-script#19826329
    # @!visibility private
    module Shell
      # @!visibility private
      DEFAULT_PRINTENV_COMMAND = "printenv -0"
      @printenv_command = DEFAULT_PRINTENV_COMMAND
      @printenv_separator = "\0"

      class << self
        # Read in the bash environment, after an optional command.
        #   Returns Array of key/value pairs.
        def shell_env(cmd = nil)
          cmd = "#{cmd} > #{IO::NULL}; " if cmd
          env = `#{cmd}#{@printenv_command} 2> #{IO::NULL}`
          if !$?.success? && @printenv_command.equal?(DEFAULT_PRINTENV_COMMAND)
            @printenv_command = "printenv"
            @printenv_separator = "\n"
            env = `#{cmd}#{@printenv_command}`
          end
          env.split(@printenv_separator).map { |l| l.split("=", 2) }
        end

        # Source a given file, and compare environment before and after.
        #   Returns Hash of any keys that have changed.
        def shell_source(file)
          (shell_env(". #{File.realpath(file)}") - shell_env).to_h
        end

        # Find variables changed as a result of sourcing the given file,
        #   and update in ENV.
        def source_env_from(file)
          shell_source(file).each { |k, v| ENV[k] = v }
        end
      end
    end
  end
end
