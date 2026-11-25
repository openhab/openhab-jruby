# frozen_string_literal: true

require "tmpdir"
require "tempfile"
require_relative "../../../../lib/openhab/thermos/runtime"

RSpec.describe OpenHAB::Thermos::Runtime do
  it "preloads once, serves multiple commands in the same process, and survives command errors" do
    log = Tempfile.new("runtime log")
    manager, connection = UNIXSocket.pair
    runtime = described_class.new(connection, {}, OpenHAB::Thermos::Env.new(root: Dir.pwd, log_file: log))
    allow(runtime).to receive(:prepare_engine_factory)
    allow(runtime).to receive(:setup)
    loads = 0
    requests = []
    allow(runtime).to receive(:preload) do
      loads += 1
      runtime.instance_variable_set(:@preloaded, true)
    end
    allow(runtime).to receive(:run_engine) do |request, streams, _client|
      requests << request
      raise "command failed" if request.fetch("args").last == "fail"

      streams[0].write(streams[2].read)
      7
    end
    worker = Thread.new { runtime.run }
    expect(manager.gets).to eq "\n"
    %w[first fail last].each do |argument|
      client, peer = UNIXSocket.pair
      input = Tempfile.new("input")
      input.write(argument)
      input.rewind
      output = Tempfile.new("output")
      error = Tempfile.new("error")
      manager.syswrite("R")
      manager.send_io(peer)
      expect(manager.gets).to eq "\n"
      expect(manager.gets.to_i).to eq Process.pid
      [output, error, input].each { |stream| client.send_io(stream.to_io) }
      json = JSON.generate("args" => ["rspec", argument])
      client.puts(json.bytesize)
      client.write(json)
      expect(client.gets).to eq "0\n"
      expect(client.gets.to_i).to eq Process.pid
      expect(client.gets.to_i).to eq((argument == "fail") ? 1 : 7)
      output.rewind
      error.rewind
      if argument == "fail"
        expect(error.read).to include("command failed")
      else
        expect(output.read).to eq argument
      end
      expect(manager.gets).to eq "done\n"
      client.close
      peer.close
      [input, output, error].each(&:close!)
    end
    expect(runtime).to have_received(:setup).with(OpenHAB::Thermos.command("rspec")).exactly(3).times
    expect(loads).to eq 1
    expect(requests.length).to eq 3
    runtime.terminate
    expect(worker.join(2)).not_to be_nil
    worker.value
  ensure
    worker&.kill
    manager&.close
    log&.close!
  end
end
