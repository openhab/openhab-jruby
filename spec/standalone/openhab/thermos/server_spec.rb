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
end
