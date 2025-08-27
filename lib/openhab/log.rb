# frozen_string_literal: true

require "forwardable"

$ctx ||= nil

module OpenHAB
  # rubocop:disable Layout/LineLength

  #
  # Provides access to the openHAB logging facilities using Ruby logging methods
  #
  # Logging is available everywhere through the {#logger} object.
  #
  # The logging prefix is `org.openhab.automation.jrubyscripting`.
  #
  # Logging within file-based rules will have the name of the file appended to
  # the logger name. Logging inside of a rule will have the id of the rule
  # appended to the logger name. Any classes will have the full class name
  # appended to the logger name.
  #
  # Logging within UI-based rules will have the rule UID appended to the logger.
  #
  # @example The following entries are in a file named 'log_test.rb'
  #   logger.trace('Test logging at trace') # 2020-12-03 18:05:20.903 [TRACE] [org.openhab.automation.jrubyscripting.log_test] - Test logging at trace
  #   logger.debug('Test logging at debug') # 2020-12-03 18:05:32.020 [DEBUG] [org.openhab.automation.jrubyscripting.log_test] - Test logging at debug
  #   logger.warn('Test logging at warn')   # 2020-12-03 18:05:41.817 [WARN ] [org.openhab.automation.jrubyscripting.log_test] - Test logging at warn
  #   logger.info('Test logging at info')   # 2020-12-03 18:05:41.817 [INFO ] [org.openhab.automation.jrubyscripting.log_test] - Test logging at info
  #   logger.error('Test logging at error') # 2020-12-03 18:06:02.021 [ERROR] [org.openhab.automation.jrubyscripting.log_test] - Test logging at error
  #
  # @example From a UI-based rule with UID 'rule_uid'
  #   logger.info('Test logging at info')   # 2020-12-03 18:05:41.817 [INFO ] [org.openhab.automation.jrubyscripting.script.rule_uid] - Test logging at info
  #
  # @example The following entries are in a file named 'log_test.rb'
  #   # Enable trace log level for all the rules in this file
  #   logger.level = :trace
  #
  #   rule 'foo' do
  #     run { logger.trace('Test logging at trace') } # 2020-12-03 18:05:20.903 [TRACE] [org.openhab.automation.jrubyscripting.log_test.rule.log_test:1] - Test logging at trace
  #     on_load
  #   end
  #
  #   rule 'foo with id', id: "foo_id" do
  #     run { logger.trace('Test logging at trace') } # 2020-12-03 18:05:20.903 [TRACE] [org.openhab.automation.jrubyscripting.log_test.rule.foo_id] - Test logging at trace
  #     on_load
  #   end
  #
  # @example A log entry from inside a class
  #   class MyClass
  #     def initialize
  #       logger.trace("hi!") # 2020-12-03 18:05:20.903 [TRACE] [org.openhab.automation.jrubyscripting.MyClass] - hi!
  #     end
  #   end
  #
  module Log
    # rubocop:enable Layout/LineLength

    # @!visibility private
    def self.included(base)
      return if base.singleton_class?

      base.singleton_class.include(self)
    end

    protected

    #
    # Retrieve the {Logger} for this class.
    #
    # @return [Logger]
    #
    def logger
      # no caching on `main`
      if (instance_of?(Object) && !singleton_methods.empty?) ||
         # also pretend loggers in example groups are in the top-level
         (defined?(::RSpec::Core::ExampleGroup) && is_a?(Module) && self < ::RSpec::Core::ExampleGroup)
        return Log.logger(:main)
      end
      return @logger ||= Log.logger(self) if equal?(self.class) || is_a?(Module)

      self.class.logger
    end

    @loggers = {}
    class << self
      #
      # Retrieve a {Logger} for a particular object.
      #
      # @param [Module,String] object Object the logger is for, or explicit name of the logger.
      # @return [Logger]
      #
      def logger(object)
        case object
        when Module
          name = Logger::PREFIX
          klass = java_klass(object)
          name += ".#{klass.name.gsub("::", ".")}" if klass.name
        when String
          name = object
        when :main
          name = "#{Logger::PREFIX}.#{current_file}"
          name = "#{name}.#{$ctx["ruleUID"]}" if $ctx&.key?("ruleUID")
          return @loggers[name] ||= BiLogger.new(Logger.new(name))
        end

        @loggers[name] ||= Logger.new(name)
      end

      #
      # Figure out the file the current rule is loaded from.
      #
      # @return [String] Prefix for log messages
      #
      # @!visibility private
      def top_level_file
        caller_locations.find { |caller| caller.base_label == "<main>" }
                        &.then { |caller| cleanup_path(caller.path) }
      end

      private

      def cleanup_path(path)
        File.basename(path, ".*").tr_s(":", "_").gsub(/[^A-Za-z0-9_.-]/, "") if path
      end

      # Get the appropriate java class for the supplied klass if the supplied
      # class is a java class
      # @param [Class] klass to inspect
      # @return Class or Java class of supplied class
      def java_klass(klass)
        if klass.respond_to?(:java_class) &&
           klass.java_class &&
           !klass.java_class.name.start_with?("org.jruby.Ruby") &&
           !klass.java_class.name.start_with?("org.jruby.gen")
          klass = klass.java_class
        end
        klass
      end

      #
      # Figure out the log prefix
      #
      # This returns the file in which `logger` is called, which can be different to the main rules file.
      #
      # @return [String] Prefix for log messages
      #
      def current_file
        caller_locations(3, 2).map(&:path)
                              .grep_v(%r{lib/openhab/log\.rb})
                              .first
                              .then { |path| cleanup_path(path) }
      end
    end
  end

  #
  # Ruby Logger that forwards messages at appropriate levels to openHAB Logger
  #
  class Logger
    # The base prefix for all loggers from this gem.
    PREFIX = "org.openhab.automation.jrubyscripting"

    # @return [Array<symbol>] Supported logging levels
    LEVELS = %i[trace debug warn info error].freeze

    #
    # Regex for matching internal calls in a stack trace
    #
    INTERNAL_CALL_REGEX = %r{(openhab-scripting-.*/lib)|org[./]jruby}
    private_constant :INTERNAL_CALL_REGEX

    #
    # Regex for matching internal calls in a java stack trace
    #
    EXCLUDED_JAVA_PACKAGES = /jdk\.internal\.reflect|java\.lang\.reflect|org\.openhab|java\.lang\.Thread\.run/
    private_constant :EXCLUDED_JAVA_PACKAGES

    #
    # Regex for matching internal calls in a java stack trace
    #
    JAVA_INTERNAL_CALL_REGEX = Regexp.union(INTERNAL_CALL_REGEX, EXCLUDED_JAVA_PACKAGES).freeze
    private_constant :JAVA_INTERNAL_CALL_REGEX

    class << self
      # The root logger (all of openHAB)
      # @return [Logger]
      def root
        Log.logger(org.slf4j.Logger::ROOT_LOGGER_NAME)
      end

      # The root logger for this gem
      # @return [Logger]
      def gem_root
        Log.logger(PREFIX)
      end

      # The events logger (events.log)
      # @return [Logger]
      def events
        Log.logger("openhab.event")
      end

      # @!visibility private
      def log_service
        @log_service = OSGi.service("org.apache.karaf.log.core.LogService")
      end

      private

      # @!macro def_level_method
      #   @!method $1(msg = nil)
      #
      #   Log a message at $1 level.
      #
      #   @param msg [Object, nil] The log message
      #   @yield
      #     Pass a block to delay generating the log message until it's
      #     confirmed that logging is enabled at $1 level.
      #   @yieldreturn [Object, nil] The log message
      #   @return [void]
      #
      #   @example
      #     logger.$1 do
      #       total = Item1.state + Item2.state
      #       average = total / 2
      #     "Total: #{total}, Average: #{average}"
      #     end
      #
      def def_level_method(level)
        define_method(level) do |msg = nil, &block|
          log(severity: level, msg:, &block)
        end
      end

      # @!macro def_level_predicate
      #   @!method $1?
      #
      #   If the logger is enabled at $1 level.
      #
      #   @return [true,false]
      #
      def def_level_predicate(level)
        define_method(:"#{level}?") { @slf4j_logger.send(:"is_#{level}_enabled") }
      end
    end

    # @!visibility private
    #
    # Create a new logger
    #
    # @param [String] name of the logger
    #
    def initialize(name)
      @slf4j_logger = org.slf4j.LoggerFactory.getLogger(name)
    end

    # The logger name
    # @return [String]
    def name
      @slf4j_logger.name
    end

    # @return [String]
    def inspect
      "#<OpenHAB::Logger #{name}>"
    end
    alias_method :to_s, :inspect

    # @!attribute [rw] level
    #
    # @note When a logger's level is modified, the logging infrastructure has
    #   to reload, and logging may be completely unavailable for a short time.
    #
    # @return [:error,:warn,:info,:debug,:trace] The current log level
    #
    # @example Retrieve the current log level
    #   level = OpenHAB::Log.logger("openhab.event.ItemStateChangedEvent").level
    #   logger.info "The log level for 'openhab.event.ItemStateChangedEvent' is #{level}"
    #
    # @example Set the log level
    #   OpenHAB::Log.logger("openhab.event.ItemStateChangedEvent").level = :warn
    #
    def level
      Logger.log_service.get_level(name)[name]&.downcase&.to_sym
    end

    def level=(level)
      return if self.level == level

      Logger.log_service.set_level(name, level.to_s)
    end

    def_level_method(:error)
    def_level_predicate(:error)
    def_level_method(:warn)
    def_level_predicate(:warn)
    def_level_method(:info)
    def_level_predicate(:info)
    def_level_method(:debug)
    def_level_predicate(:debug)
    def_level_method(:trace)
    def_level_predicate(:trace)

    #
    # Print error and stack trace without calls to internal classes
    #
    # @param [Exception] exception A rescued error
    # @return [void]
    #
    def log_exception(exception)
      exception = clean_backtrace(exception)
      error do
        "#{exception.message} (#{exception.class})\n#{exception.backtrace&.join("\n")}"
      end
    end

    private

    #
    # Cleans the backtrace of an error to remove internal calls. If logging is set
    # to debug or lower, the full backtrace is kept
    #
    # @param [Exception] error An exception to be cleaned
    #
    # @return [Exception] the exception, potentially with a cleaned backtrace.
    #
    def clean_backtrace(error)
      return error if debug?

      if error.respond_to? :backtrace_locations
        backtrace = error.backtrace_locations&.map(&:to_s)&.grep_v(INTERNAL_CALL_REGEX)
        error.set_backtrace(backtrace) if backtrace
      elsif error.respond_to? :stack_trace
        backtrace = error.stack_trace.reject { |line| JAVA_INTERNAL_CALL_REGEX.match? line.to_s }
        error.set_stack_trace(backtrace)
      end
      error
    end

    #
    # Log a message to the openHAB Logger
    #
    # @param [Symbol] severity Severity to log message at
    # @param [Object] msg to log, if no msg supplied and a block is provided,
    #   the msg is taken from the result of the block
    #
    def log(severity:, msg: nil)
      raise ArgumentError, "Unknown Severity #{severity}" unless LEVELS.include? severity

      # Dynamically check enablement of underlying logger
      return unless send(:"#{severity}?")

      # Process block if no message provided
      msg = yield if msg.nil? && block_given?

      @slf4j_logger.send(severity, msg.to_s)
    end
  end

  module Log
    # Logger that changes its backing logger depending on thread context
    class BiLogger < Logger
      @rule_loggers = {}
      class << self
        # class shared cache of loggers-per-rule
        attr_reader :rule_loggers
      end

      def initialize(file_logger) # rubocop:disable Lint/MissingSuper
        @file_logger = file_logger
      end

      # The current logger - the file logger if rule_uid is nil,
      # otherwise a logger specific to the rule.
      def current_logger
        return @file_logger unless (rule_uid = Thread.current[:openhab_rule_uid])

        rule_type = Thread.current[:openhab_rule_type]
        top_level_file = Log.top_level_file&.then { |file| "#{file}." }
        full_id = "#{rule_type}:#{rule_uid}"

        self.class.rule_loggers[full_id] ||= Logger.new("#{Logger::PREFIX}.#{top_level_file}#{rule_type}.#{rule_uid
            .gsub(/[^A-Za-z0-9_.:-]/, "")}")
      end

      extend Forwardable

      def_delegators :current_logger, *(Logger.public_instance_methods.select do |m|
        Logger.instance_method(m).owner == Logger
      end - BasicObject.public_instance_methods)
    end
    private_constant :BiLogger
  end

  Object.include(Log)
end
