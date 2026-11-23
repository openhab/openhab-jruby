# frozen_string_literal: true

# SPDX-License-Identifier: MIT
# Derived from Spring; see lib/openhab/thermos/LICENSE and NOTICE.md.

# Loaded inside a fresh JRuby Scripting engine for each client request.
shared_context = thermos_context
context = shared_context.to_h
thread = Thread.current
status = nil
source_input = nil
input_nonblock = nil
streams = {}
begin
  shared_context.put("interrupt", java.lang.Runnable.impl do
    signal = shared_context.get("signal") || "INT"
    if (handler = context["on_interrupt"])
      handler.call(signal)
    elsif signal == "INT"
      shared_context.put("interrupted", true)
      thread.raise(Interrupt)
    else
      thread.raise(SystemExit.new(128 + Signal.list.fetch(signal)))
    end
  end)

  $LOAD_PATH.unshift(File.expand_path("../..", __dir__))
  require "openhab/thermos"
  OpenHAB::Thermos.context = context
  ENV.replace(context.fetch("env").to_h)
  require "rubygems"
  Gem.clear_paths
  require "io/nonblock"
  Dir.chdir(context.fetch("cwd"))
  source_input = IO.for_fd(context.fetch("stdin"), "r", autoclose: false)
  input_nonblock = source_input.nonblock?
  # The engine owns duplicates; the server retains its original descriptors.
  %w[stdin stdout stderr].each do |name|
    source = IO.for_fd(context.fetch(name), (name == "stdin") ? "r" : "w", autoclose: false)
    stream = source.dup
    stream.autoclose = true
    streams[name] = stream
  end
  $stdin = streams.fetch("stdin")
  $stdout = streams.fetch("stdout")
  $stderr = streams.fetch("stderr")
  # Let JRuby wait for readiness so a blocked read can receive Interrupt.
  $stdin.nonblock = true
  $stdout.sync = $stderr.sync = true
  $stdout.define_singleton_method(:tty?) { context.fetch("tty") }
  $stdout.define_singleton_method(:isatty) { tty? }
  { STDIN: $stdin, STDOUT: $stdout, STDERR: $stderr }.each do |name, stream|
    Object.send(:remove_const, name)
    Object.const_set(name, stream)
  end

  require "bundler/setup"
  require "openhab/thermos/commands"

  ARGV.replace(context.fetch("args").to_a)
  if (command = OpenHAB::Thermos.command(context["command"]))
    $PROGRAM_NAME = command.exec_name
    srand

    shared_context.get("interrupt").run if shared_context.get("signal")
    command.call

    status = 0
  end
rescue SystemExit => e
  status = e.status
rescue Interrupt
  status = 130
ensure
  begin
    scriptUnloaded if respond_to?(:scriptUnloaded, true)
  ensure
    # Duplicates share file status flags with the original client descriptor.
    source_input.nonblock = input_nonblock unless input_nonblock.nil?
    streams.each_value { |stream| stream.close unless stream.closed? }
    shared_context.put("status", shared_context.get("interrupted") ? 130 : status)
  end
end
