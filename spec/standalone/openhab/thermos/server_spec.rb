# frozen_string_literal: true

require "stringio"
require "tmpdir"
require "timeout"
require "rbconfig"
require_relative "../../../../lib/openhab/thermos/server"

RSpec.describe OpenHAB::Thermos::Server do
  let(:directory) { Dir.mktmpdir("thermos-server") }
  let(:environment) { OpenHAB::Thermos::Env.new(root: directory, log_file: StringIO.new) }
  let(:server) { described_class.new(foreground: true, env: environment) }
  let(:listener) { UNIXServer.new(environment.socket_name) }

  before do
    allow(environment).to receive(:tmp_path).and_return(Pathname.new(directory))
    allow(environment).to receive(:require_jruby!)
    allow(OpenHAB::Thermos).to receive(:verify_environment)
    allow(OpenHAB::Thermos::ProcessTitleUpdater).to receive(:run)
    allow(server).to receive(:trap)
    allow(server).to receive(:start_server) { server.instance_variable_set(:@server, listener) }
  end

  after do
    server.shutdown
    FileUtils.remove_entry(directory)
  end

  it "acknowledges queued clients while serializing runtime replacement and execution" do
    events = Queue.new
    release = Queue.new
    connections = []
    first_env = { "RUNTIME" => "first" }
    second_env = { "RUNTIME" => "second" }
    first_runtime = instance_double(OpenHAB::Thermos::RuntimeManager, spawn_env: first_env)
    second_runtime = instance_double(OpenHAB::Thermos::RuntimeManager, spawn_env: second_env, stop: nil)
    allow(first_runtime).to receive(:stop) { events << :stopped }
    [[first_runtime, :first], [second_runtime, :second]].each do |runtime, name|
      allow(runtime).to receive(:run) do |client|
        events << name
        release.pop
        client.close
      end
    end
    allow(OpenHAB::Thermos::RuntimeManager).to receive(:new).with(first_env, environment).and_return(first_runtime)
    allow(OpenHAB::Thermos::RuntimeManager).to receive(:new).with(second_env, environment).and_return(second_runtime)
    allow(server).to receive(:start_server).and_call_original
    coordinator = Thread.new { server.boot }
    Timeout.timeout(5) { sleep 0.01 until environment.socket_path.exist? }

    connect_request(first_env, connections)
    expect(Timeout.timeout(5) { events.pop }).to eq :first
    connect_request(second_env, connections)
    expect(events).to be_empty
    release << true
    expect(Timeout.timeout(5) { events.pop }).to eq :stopped
    expect(Timeout.timeout(5) { events.pop }).to eq :second
    release << true
  ensure
    coordinator&.kill
    coordinator&.join(5)
    connections&.each { |connection| connection.close unless connection.closed? }
  end

  it "cleans up after a real Ctrl-C and allows the next foreground server to start" do
    File.write(File.join(directory, "Gemfile"), "")
    log = File.join(directory, "foreground.log")
    lib = File.expand_path("../../../../lib", __dir__)
    script = <<~RUBY
      require "openhab/thermos/server"
      env = OpenHAB::Thermos::Env.new
      def env.require_jruby!; end
      OpenHAB::Thermos::Server.new(foreground: true, env: env).boot
    RUBY
    child_env = {
      "BUNDLE_GEMFILE" => File.join(directory, "Gemfile"),
      "THERMOS_TMP_PATH" => directory,
      "RUBYOPT" => nil,
      "BUNDLER_SETUP" => nil,
      "BUNDLE_LOCKFILE" => nil
    }
    command = [RbConfig.ruby, "-I", lib, "-e", script]
    pid = nil
    2.times do
      pid = Process.spawn(child_env, *command, in: File::NULL, out: log, err: log)
      status = Timeout.timeout(20) do
        sleep 0.05 until environment.socket_path.exist?
        Process.kill("INT", pid)
        Process.wait2(pid).last
      end
      pid = nil
      expect(status.success?).to be(true), File.read(log)
      expect(environment.socket_path).not_to exist
      expect(environment.pidfile_path).not_to exist
    end
  ensure
    if pid
      begin
        Process.kill("KILL", pid)
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end
    end
  end

  it "cleans up when the foreground accept loop returns" do
    server.boot
    expect(listener).to be_closed
    expect(environment.socket_path).not_to exist
    expect(environment.pidfile_path).not_to exist
  end

  it "removes the socket and pidfile even when runtime shutdown fails" do
    runtime = instance_double(OpenHAB::Thermos::RuntimeManager)
    allow(runtime).to receive(:stop).and_raise(IOError, "shutdown failed")
    server.instance_variable_set(:@runtime, runtime)
    expect { server.boot }.to raise_error(IOError, "shutdown failed")
    expect(listener).to be_closed
    expect(environment.socket_path).not_to exist
    expect(environment.pidfile_path).not_to exist
  end

  it "leaves another server's files and listener intact when its pidfile is locked" do
    server.write_pidfile
    server.instance_variable_set(:@server, listener)
    other = described_class.new(foreground: true, env: environment)
    other.boot
    expect(environment.socket_path).to exist
    expect(environment.pidfile_path).to exist
    expect(listener).not_to be_closed
  ensure
    other&.shutdown
  end

  def connect_request(spawn_env, connections)
    client = UNIXSocket.open(environment.socket_name)
    transport, forwarded = UNIXSocket.pair
    forwarded.nonblock = false
    connections.push(client, transport, forwarded)
    expect(Timeout.timeout(5) { client.gets }).to eq "#{environment.version}\n"
    client.send_io(forwarded)
    json = JSON.dump("args" => ["console"], "spawn_env" => spawn_env, "reset_env" => {})
    client.puts(json.bytesize)
    client.write(json)
    expect(Timeout.timeout(5) { client.gets }).to eq "\n"
  end
end
