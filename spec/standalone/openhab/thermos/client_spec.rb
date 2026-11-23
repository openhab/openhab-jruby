# frozen_string_literal: true

require "tmpdir"
require "tempfile"
require "timeout"
require_relative "../../../../lib/openhab/thermos/client"

# rubocop:disable-next RSpec/ExpectOutput
RSpec.describe OpenHAB::Thermos::Client do
  around do |example|
    original_streams = [$stdin, $stdout, $stderr]
    original_env = ENV.to_h
    Dir.mktmpdir do |directory|
      ENV["BUNDLE_GEMFILE"] = File.join(directory, "Gemfile")
      ENV["THERMOS_TMP_PATH"] = File.join(directory, "transport")
      File.write(ENV.fetch("BUNDLE_GEMFILE"), "source 'https://rubygems.org'\n")
      Dir.chdir(directory) { example.run }
    end
  ensure
    $stdin, $stdout, $stderr = original_streams
    ENV.replace(original_env)
  end

  it "passes native stdin/stdout/stderr descriptors and forwards the exit status" do
    environment = OpenHAB::Thermos::Env.new
    listener = UNIXServer.new(environment.socket_name)
    input, writer = IO.pipe
    writer.write("input\n")
    writer.close
    output = Tempfile.new("client output")
    error = Tempfile.new("client error")
    $stdin = input
    $stdout = output
    $stderr = error
    request = nil
    received_input = nil
    blocking = nil
    coordinator = Thread.new do
      connection = listener.accept
      connection.puts(environment.version)
      runtime = connection.recv_io(UNIXSocket)
      blocking = !runtime.nonblock?
      connection.read(connection.gets.to_i)
      connection.puts
      streams = Array.new(3) { runtime.recv_io }
      request = JSON.parse(runtime.read(runtime.gets.to_i))
      runtime.puts(0)
      runtime.puts(Process.pid)
      received_input = streams[2].read
      streams[0].write("output\xFF".b)
      streams[1].write("warning\n")
      streams.each(&:close)
      runtime.puts(7)
      runtime.close
      connection.close
    end
    expect { described_class.run(["rspec", "spec/foo_spec.rb:12", "--format", "documentation"]) }
      .to raise_error(SystemExit) { |exit| expect(exit.status).to eq 7 }
    coordinator.value
    expect(request.fetch("args")).to eq ["rspec", "spec/foo_spec.rb:12", "--format", "documentation"]
    expect(request.fetch("env")).to include("PATH" => ENV.fetch("PATH"))
    expect(received_input).to eq "input\n"
    expect(blocking).to be true
    output.rewind
    error.rewind
    expect(output.read.b).to eq "output\xFF".b
    expect(error.read).to eq "warning\n"
  ensure
    listener&.close
    input&.close
    output&.close!
    error&.close!
    coordinator&.kill
  end

  it "restarts after a stale UNIX socket refuses the connection" do
    client = OpenHAB::Thermos::Client::Run.new(["console"])
    UNIXServer.new(client.env.socket_name).close
    listener = nil
    allow(client).to receive(:boot_server) do
      FileUtils.rm_f(client.env.socket_path)
      listener = UNIXServer.new(client.env.socket_name)
    end

    client.connect

    expect(client).to have_received(:boot_server).once
    expect(client.server).not_to be_closed
    listener.accept.close
  ensure
    client&.server&.close
    listener&.close
  end

  it "does not hide unrelated IO errors while connecting" do
    client = OpenHAB::Thermos::Client::Run.new(["console"])
    allow(UNIXSocket).to receive(:open).and_raise(IOError, "closed stream")
    expect(client).not_to receive(:boot_server)
    expect { client.connect }.to raise_error(IOError, "closed stream")
  end

  it "forwards a signal without reading an acknowledgement or stealing the exit status" do
    runtime, peer = UNIXSocket.pair
    handlers = {}
    allow(Signal).to receive(:trap) do |signal, &handler|
      handlers[signal] = handler
      "DEFAULT"
    end
    client = OpenHAB::Thermos::Client::Run.new(["console"])
    client.forward_signals(runtime)

    Timeout.timeout(2) { handlers.fetch("INT").call }
    expect(peer.gets).to eq "INT\n"
    peer.puts(130)
    expect(runtime.gets).to eq "130\n"
  ensure
    peer&.close
    runtime&.close
  end

  it "reports a missing server" do
    expect(OpenHAB::Thermos::Env.new.server_running?).to be false
    expect { described_class.run(["status"]) }.to output(/not running/).to_stdout
    expect { described_class.run(["stop"]) }.to output(/not running/).to_stdout
  end

  context "when the client uses CRuby" do
    before { stub_const("RUBY_ENGINE", "ruby") }

    it "explains how to start a missing server without spawning CRuby" do
      expect do
        expect { described_class.run(["rspec"]) }.to raise_error(SystemExit) { |exit| expect(exit.status).to eq 1 }
      end.to output(/Retry with JRuby; once the server is running, you can switch to CRuby/).to_stderr
      expect(OpenHAB::Thermos::Env.new.pid).to be_nil
    end

    it "reports the JRuby startup requirement when a stale socket is left behind" do
      UNIXServer.new(OpenHAB::Thermos::Env.new.socket_name).close
      expect do
        expect { described_class.run(["console"]) }.to raise_error(SystemExit) { |exit| expect(exit.status).to eq 1 }
      end.to output(/Retry with JRuby; once the server is running, you can switch to CRuby/).to_stderr
    end

    it "rejects a foreground server before loading Java" do
      expect do
        expect { described_class.run(["server"]) }.to raise_error(SystemExit) { |exit| expect(exit.status).to eq 1 }
      end.to output(/server must be started under JRuby/).to_stderr
    end
  end
end
