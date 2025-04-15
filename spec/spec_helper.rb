# frozen_string_literal: true

Bundler.require(:default, :test)

require "openhab/rspec/configuration"
OpenHAB::RSpec::Configuration.use_root_instance = true

# clean any external OPENHAB or KARAF references; we want to use our private install
ENV.delete_if { |k| k.match?(/^(?:OPENHAB|KARAF)_/) }
ENV["OPENHAB_HOME"] = "#{Dir.pwd}/tmp/openhab"
ENV["TZ"] = "UTC"
java.util.TimeZone.default = java.util.TimeZone.get_time_zone("Etc/UTC")

require "openhab/rspec"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.allow_message_expectations_on_nil = false
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random

  def fixture(filename)
    File.expand_path("../features/assets/#{filename}", __dir__)
  end

  config.before(:suite) do
    OpenHAB::Logger.gem_root.level = :trace
    OpenHAB::Log.logger("org.openhab.automation.jrubyscripting.internal").level = :warn

    # set up stdio streams for console specs here, since we can only do it once
    # per process
    $terminal = Object.new
    def $terminal.type; end
    $console = Object.new
    def $console.session
      @session ||= Object.new
      def @session.terminal = $terminal
      @session
    end
    require "openhab/console"
  end

  config.around(console: true) do |example|
    stdin, stdout, stderr = $stdin, $stdout, $stderr # rubocop:disable Style/ParallelAssignment

    example.run
  ensure
    $stdin, $stdout, $stderr = stdin, stdout, stderr # rubocop:disable Style/ParallelAssignment
  end

  config.before(console: true) do
    input = instance_double(org.jline.utils.NonBlockingInputStream)
    writer = instance_double(java.io.PrintWriter, print: nil, flush: nil)
    encoding = instance_double(java.nio.charset.Charset, name: "UTF-8")
    $terminal = double("org.jline.terminal.Terminal", encoding:, input:, writer:) # rubocop:disable RSpec/VerifiedDoubles -- this is an interface, so non-default methods don't exist from Ruby's perspective

    require "openhab/console/stdio"

    # recreate these each time, so that they're using the current mock
    $stdin = OpenHAB::Console::Stdin.new($terminal)
    $stdout = $stderr = OpenHAB::Console::Stdout.new($terminal)
  end

  Kernel.srand config.seed
end
