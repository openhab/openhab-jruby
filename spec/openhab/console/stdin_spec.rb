# frozen_string_literal: true

RSpec.describe "OpenHAB::Console::Stdin", :console do
  describe "#ungetc" do
    it "encodes the character to the external encoding" do
      $stdin.ungetc("\u20ac")
      expect($stdin.getbyte).to be 0xe2
      expect($stdin.getbyte).to be 0x82
      expect($stdin.getbyte).to be 0xac
    end
  end
end
