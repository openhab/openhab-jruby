# frozen_string_literal: true

require_relative "../../../../lib/openhab/thermos"

RSpec.describe "Binstub bootstrap" do
  [nil, "", "0"].each do |disable|
    it "does not invoke the client inside an engine with disable=#{disable.inspect}" do
      previous_context = OpenHAB::Thermos.context
      previous_program = $PROGRAM_NAME
      previous_disable = ENV["DISABLE_THERMOS"]
      original_args = ARGV.dup
      OpenHAB::Thermos.context = {}
      $PROGRAM_NAME = "rspec"
      disable ? ENV["DISABLE_THERMOS"] = disable : ENV.delete("DISABLE_THERMOS")

      load File.expand_path("../../../../lib/openhab/thermos/binstub.rb", __dir__)

      expect(ARGV).to eq original_args
    ensure
      OpenHAB::Thermos.context = previous_context
      $PROGRAM_NAME = previous_program
      ENV["DISABLE_THERMOS"] = previous_disable
      ARGV.replace(original_args)
    end
  end
end
