# frozen_string_literal: true

require "openhab/console/stdio"

module OpenHAB
  module Console
    #
    # A basic JRuby REPL for openHAB Karaf console
    #
    # To use this, set the jrubyscripting add-on `console` configuration to `jline`
    #
    class JLine
      # Create constants instead of java_import to avoid polluting the global namespace
      LineReader = org.jline.reader.LineReader
      Bracket = org.jline.reader.impl.DefaultParser::Bracket

      BOLD = "\e[1m"
      RESET = "\e[0m"
      RED = "\e[31m"
      GREEN = "\e[32m"
      YELLOW = "\e[33m"
      BLUE = "\e[34m"
      CYAN = "\e[36m"

      ERROR = RED
      STRING = BOLD + YELLOW
      NUMBER = BOLD + BLUE
      OBJECT = BOLD + GREEN
      SIMPLE_CLASS = BOLD + CYAN
      PROMPT = "#{BOLD}JRuby> #{RESET}".freeze

      class << self
        def start
          puts "Welcome to JRuby REPL. Press Ctrl+D to exit, Alt+Enter (or Esc,Enter) to insert a new line."

          console = new

          loop do
            begin
              input = console.read_line
              next if input.strip.empty?
            rescue org.jline.reader.UserInterruptException # Ctrl+C is pressed
              next
            rescue org.jline.reader.EndOfFileException # Ctrl+D is pressed
              break
            end

            begin
              # Use TOPLEVEL_BINDING to isolate and keep the local variables between loops
              result = TOPLEVEL_BINDING.eval(input)
              console.print_result(result)
            rescue Exception => e
              console.print_error(e)
            end
          end
        end
      end

      def initialize
        parser = org.jline.reader.impl.DefaultParser.new
                    .eof_on_unclosed_bracket(Bracket::CURLY, Bracket::ROUND, Bracket::SQUARE)
                    .eof_on_unclosed_quote(true)
                    .eof_on_escaped_new_line(true)

        completer =
          org.jline.reader.Completer.impl do |_method_name, _reader, _line, candidates|
            sources = TOPLEVEL_BINDING.local_variables + Object.constants
            sources += DSL.items.map(&:name) + DSL.methods(false) if defined?(DSL)

            candidates.add_all(sources.map { |c| org.jline.reader.Candidate.new(c.to_s) })
          end

        @reader = org.jline.reader.LineReaderBuilder.builder
                     .terminal($terminal)
                     .app_name("jrubyscripting")
                     .parser(parser)
                     .completer(completer)
                     .variable(LineReader::SECONDARY_PROMPT_PATTERN, "%M%P > ")
                     .variable(LineReader::INDENTATION, 2)
                     .build
      end

      def read_line
        @reader.read_line(PROMPT)
      end

      def print_result(result)
        puts "=> " + # rubocop:disable Style/StringConcatenation
             case result
             when nil, true, false then SIMPLE_CLASS + result.inspect + RESET
             when String then %("#{STRING}#{result.dump[1..-2]}#{RESET}")
             when Numeric, Array, Hash then NUMBER + result.to_s + RESET
             else OBJECT + result.inspect + RESET
             end
      end

      def print_error(error)
        puts ERROR + "Error: #{error.message}" + RESET
      end
    end
  end
end

OpenHAB::Console::JLine.start
