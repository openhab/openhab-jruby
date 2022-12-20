# frozen_string_literal: true

require "fileutils"
require "open-uri"
require "tty-command"
require "process_exists"
require "erb"
require "digest/md5"
require "net/http"

# Disabled due to part of buid / potentially refactor into classes
# rubocop: disable Rake/MethodDefinitionInTask Legacy code
namespace :openhab do
  @openhab_version = ENV["OPENHAB_VERSION"] || "4.0.0-SNAPSHOT"
  @port_numbers = {
    ssh: { port: ENV["OPENHAB_SSH_PORT"] || 8101, config: "org.apache.karaf.shell:sshPort" },
    lsp: { port: ENV["OPENHAB_LSP_PORT"] || 5007, config: "org.openhab.lsp:port" }
  }
  karaf_client_path = File.join(OPENHAB_DIR, "runtime/bin/client")
  karaf_client_args = [karaf_client_path, "-a", @port_numbers[:ssh][:port], "-p", "habopen"].freeze
  @karaf_client = karaf_client_args.join(" ")
  @cache_dir = File.expand_path("cache")
  @deploy_dir = File.join(OPENHAB_DIR, "conf/automation/jsr223/ruby/personal")
  @state_dir = File.join(OPENHAB_DIR, "rake_state")
  @services_config_file = File.join(OPENHAB_DIR, "conf/services/jruby.cfg")
  @addons_config_file = File.join(OPENHAB_DIR, "conf/services/addons.cfg")
  @port_config_file = File.join(OPENHAB_DIR, "conf/services/port_config.cfg")

  CLOBBER << OPENHAB_DIR
  CLOBBER << @services_config_file
  CLOBBER << @port_config_file
  CLOBBER << TMP_DIR
  CLEAN << @deploy_dir

  def command_success?(command)
    cmd = TTY::Command.new(printer: :null)
    cmd.run!(command).success?
  end

  def running?(fail_on_error: false)
    karaf_status = File.join(OPENHAB_DIR, "runtime/bin/status")

    return false unless File.exist? karaf_status

    if fail_on_error
      fail_on_error(karaf_status)
      true
    else
      command_success? karaf_status
    end
  end

  # Get openhab http port
  def openhab_port
    command = "#{@karaf_client} 'system:property org.osgi.service.http.port'"

    cmd = TTY::Command.new(printer: :null)
    cmd.run!(command).out.chomp
  end

  # Check if openhab is listening on port 8080
  def http_ready?
    uri = URI("http://127.0.0.1/")
    uri.port = openhab_port
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri
      response = http.request request
      return response.is_a? Net::HTTPSuccess
    end
  end

  # There can be a delay between when openHAB is running and ready to process commands
  def ready?(fail_on_error: false)
    return unless running?

    command = "#{@karaf_client} 'system:start-level'"

    cmd = TTY::Command.new(printer: :null)
    ready = cmd.run!(command).out.chomp.casecmp?("Level 100")
    ready &&= http_ready?
    raise "openHAB is not ready" if !ready && fail_on_error

    ready
  end

  def ensure_openhab_running
    abort("openHAB not running") unless running?
  end

  def print_and_flush(string)
    print string
    $stdout.flush
  end

  def fail_on_error(command, env = {})
    cmd = TTY::Command.new
    out, = cmd.run(command, env: env, only_output_on_error: true)
    out
  end

  def karaf(command)
    fail_on_error("#{@karaf_client} '#{command}'")
  end

  def wait_for(duration, task)
    print_and_flush "Waiting for up to #{duration} seconds for #{task}"
    duration.times do
      return true if yield

      print_and_flush "."
      sleep 1
    end
    false
  ensure
    puts ""
  end

  def gem_home
    full_path = File.realpath OPENHAB_DIR
    File.join(full_path, "/conf/scripts/lib/ruby/gem_home")
  end

  def ruby_lib_dir
    full_path = File.realpath OPENHAB_DIR
    File.join(full_path, "/conf/automation/lib/ruby/personal")
  end

  def ruby_env
    { "GEM_HOME" => gem_home }
  end

  def state(task)
    Rake::Task[@state_dir.to_s].execute
    task_file = File.join(@state_dir, task).tr(":", "_")
    if File.exist?(task_file)
      puts "Skipping task(#{task}), task already up to date"
    else
      yield
      touch task_file
    end
  end

  directory @cache_dir
  directory OPENHAB_DIR
  directory @deploy_dir
  directory @state_dir

  desc "Download Openhab and unzip it"
  task download: [@cache_dir, OPENHAB_DIR] do |task|
    state(task.name) do
      openhab_zip = "openhab-#{@openhab_version}.zip"
      download_url = case @openhab_version
                     when /.*-SNAPSHOT/
                       "https://ci.openhab.org/job/openHAB-Distribution/lastSuccessfulBuild/artifact/" \
                       "distributions/openhab/target/#{openhab_zip}"
                     else
                       # The same for releases and milestones
                       "https://github.com/openhab/openhab-distro/releases/download/" \
                       "#{@openhab_version}/#{openhab_zip}"
                     end
      openhab_zip = File.join(@cache_dir, openhab_zip)
      unless File.exist?(openhab_zip)
        begin
          puts "Downloading #{openhab_zip} from #{download_url}"
          URI.parse(download_url).open do |download_stream|
            IO.copy_stream(download_stream, openhab_zip)
          end
        rescue
          FileUtils.rm_f(openhab_zip)
          raise
        end
      end
      Dir.chdir(OPENHAB_DIR) do
        fail_on_error("unzip #{openhab_zip}")
      end
    end
  end

  desc "Setup services config"
  task services: [:download] do |task|
    state(task.name) do
      mkdir_p gem_home
      mkdir_p ruby_lib_dir
      services_config = ERB.new <<~SERVICES
        org.openhab.automation.jrubyscripting:gem_home=<%= gem_home %>
        org.openhab.automation.jrubyscripting:rubylib=<%= ruby_lib_dir %>
      SERVICES
      File.write(@services_config_file, services_config.result)
    end
  end

  def bundle_id
    karaf("bundle:list --no-format org.openhab.automation.jrubyscripting").lines.last[/^\d\d\d/].chomp
  end

  desc "Install JRuby Bundle"
  task bundle: [:download, :services, @deploy_dir] do |task|
    state(task.name) do
      File.write(@addons_config_file, "\nautomation=jrubyscripting,pidcontroller\n", mode: "a")
    end
  end

  desc "Upgrade JRuby Bundle"
  task :upgrade, [:file] do |_, args|
    start
    if karaf("bundle:list --no-format org.openhab.automation.jrubyscripting").include?("Active")
      source = args[:file] ? "file://#{args[:file]}" : @jruby_bundle
      karaf("bundle:update #{bundle_id} #{source}")
    else
      abort "Bundle not installed, can't upgrade"
    end
  end

  def configure_ports
    port_config = @port_numbers.values.map { |service| "#{service[:config]} = #{service[:port]}" }.join("\n")
    File.write(@port_config_file, port_config) unless port_config.empty?
  end

  desc "Configure"
  task configure: %i[download] do |task|
    # Set log levels
    state(task.name) do
      configure_ports
      start
      karaf("log:set TRACE org.openhab.automation.jruby")
      karaf("log:set TRACE org.openhab.core.automation")
      karaf("log:set TRACE org.openhab.automation.jrubyscripting")
      karaf("openhab:users add foo foo administrator")
      karaf("config:property-set -p org.openhab.restauth allowBasicAuth true")
      sh "rsync", "-aih", "config/userdata/", File.join(OPENHAB_DIR, "userdata")
    end
  end

  def karaf_log
    File.join(TMP_DIR, "karaf.log")
  end

  def restart
    puts "Restarting openHAB"
    stop
    start
    puts "openHAB Restarted"
  end

  def wait_till_running
    wait_for(30, "openHAB to start") { running? }
    abort "Unable to start openHAB" unless running?(fail_on_error: true)

    wait_for(30, "openHAB to become ready") { ready? }
    abort "openHAB did not become ready" unless ready?(fail_on_error: true)
  end

  def openhab_env
    {
      "LANG" => ENV.fetch("LANG", nil),
      "JAVA_HOME" => ENV.fetch("JAVA_HOME", nil),
      "KARAF_REDIRECT" => karaf_log,
      "EXTRA_JAVA_OPTS" => "-Xmx4g",
      "OPENHAB_HTTP_PORT" => ENV["OPENHAB_HTTP_PORT"] || "8080",
      "OPENHAB_HTTPS_PORT" => ENV["OPENHAB_HTTPS_PORT"] || "8443"
    }
  end

  def start
    return puts "openHAB already running" if running?

    Dir.chdir(OPENHAB_DIR) do
      puts "Starting openHAB"
      # Running inside of bundler breaks GEM_HOME, so we run with a clean environment passing through
      # only specific variables
      pid = spawn(openhab_env, "runtime/bin/start", unsetenv_others: true)
      Process.detach(pid)
    end
    wait_till_running
    puts "openHAB started and ready"
  end

  desc "Start openHAB"
  task start: %i[download] do
    start
  end

  desc "Start openHAB Karaf Client"
  task :client do
    exec(@karaf_client)
  end

  def stop
    if running?
      pid = File.read(File.join(OPENHAB_DIR, "userdata/tmp/karaf.pid")).chomp.to_i
      Dir.chdir(OPENHAB_DIR) do
        fail_on_error("runtime/bin/stop")
      end
      stopped = wait_for(60, "openHAB to stop") { Process.exists?(pid) == false }
      abort "Unable to stop openHAB" unless stopped
    end

    puts "openHAB Stopped"
  end

  desc "Stop openHAB"
  task :stop do
    stop
  end

  desc "Clobber local Openhab"
  task :clobber do
    stop if running?

    rm_rf OPENHAB_DIR
  end

  desc "Warmup OpenHab environment"
  task warmup: [:prepare, @deploy_dir] do
    start
    openhab_log = File.join(OPENHAB_DIR, "userdata/logs/openhab.log")

    file = File.join("openhab_rules", "warmup.rb")
    dest_file = File.join(@deploy_dir, "#{File.basename(file, ".rb")}_#{Time.now.to_i}.rb")
    cp file, dest_file
    wait_for(20, "openHAB to warmup") do
      File.foreach(openhab_log).grep(/openHAB warmup complete/).any?
    end
    rm dest_file
  end

  desc "Prepare local Openhab"
  task prepare: %i[download configure bundle deploy]

  desc "Setup local Openhab"
  task setup: %i[prepare stop]

  desc "Deploy to local Openhab"
  task deploy: %i[download build] do |_task|
    mkdir_p gem_home
    gem_file = File.join(PACKAGE_DIR, "openhab-jrubyscripting-#{OpenHAB::DSL::VERSION}.gem")
    fail_on_error("gem install #{gem_file} -i #{gem_home} --no-document")
  end

  desc "Clean up local gems"
  task :cleanupgems do
    fail_on_error("gem uninstall openhab-jrubyscripting -a", ruby_env)
  end

  desc "Deploy adhoc test Openhab"
  task adhoc: [:deploy, @deploy_dir] do
    Dir.glob(File.join(@deploy_dir, "*.rb")) { |file| rm file }
    Dir.glob(File.join("test/", "*.rb")) do |file|
      dest_name = "#{File.basename(file, ".rb")}_#{Time.now.to_i}.rb"
      cp file, File.join(@deploy_dir, dest_name)
    end
  end
end

# rubocop: enable Rake/MethodDefinitionInTask
