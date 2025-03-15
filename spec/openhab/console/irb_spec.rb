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
end
