# frozen_string_literal: true

require "timeout"

RSpec.describe "OpenHAB::Console::IRB", :console do
  before do
    next if defined?(IRB)

    # Don't actually start IRB here
    require "irb"
    start = IRB.method(:start)
    def IRB.start(*); end

    require "openhab/console/irb"
  ensure
    IRB.define_method(:start, &start) if start
  end

  around do |example|
    Timeout.timeout(5, &example) # make sure we dont' get stuck
  end

  it "loads" do
    $stdin.ungetc("\x04") # just immediately exit
    IRB.start("karaf")
  end

  it "reports the replacement stdin's terminal status to IRB" do
    allow($stdin).to receive(:tty?).and_return(true)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TERM").and_return("xterm")

    IRB.init_config("karaf")
    expect(STDIN.tty?).to be(true) # rubocop:disable Style/GlobalStdStream

    irb = IRB::Irb.new
    expect(irb.context.io).to be_a(IRB::RelineInputMethod)
    expect(irb.context.prompt_i).not_to be_nil
  end
end
