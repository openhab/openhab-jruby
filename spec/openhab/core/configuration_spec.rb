# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Configuration do
  let(:contents) do
    { "key1" => "value1", "key2" => "value2" }.freeze
  end

  let(:configuration) do
    described_class.new(contents)
  end

  describe "#inspect" do
    it "logs the full configuration" do
      expect(configuration.inspect).to eql contents.inspect
    end
  end

  describe "#to_h" do
    it "works" do
      expect(configuration.to_h).to eql contents
    end
  end

  describe "#[]" do
    it "works" do
      expect(configuration["key1"]).to eql "value1"
    end

    it "returns nil for nonexistent key" do
      expect(configuration["nonexistent"]).to be_nil
    end

    it "stringifies config keys" do
      expect(configuration[:key1]).to eql "value1"
    end
  end

  describe "#[]=" do
    it "works" do
      configuration["key1"] = "newvalue"
      expect(configuration["key1"]).to eql "newvalue"
    end

    it "stringifies config keys" do
      configuration[:key1] = "stringified"
      expect(configuration["key1"]).to eql "stringified"
    end

    it "can be added via hash" do
      configuration["newkey"] = "corge"
      expect(configuration["newkey"]).to eql "corge"
    end
  end

  describe "#dig" do
    it "works" do
      expect(configuration.dig("key1")).to eql "value1" # rubocop:disable Style/SingleArgumentDig
    end

    it "stringifies keys" do
      expect(configuration.dig(:key1)).to eql "value1" # rubocop:disable Style/SingleArgumentDig
    end
  end

  describe "#==" do
    it "can compare against a ::Hash" do
      expect(configuration).to eq(contents)
    end

    it "can compare against another Configuration object" do
      expect(configuration).to eq(described_class.new(contents))
    end
  end

  describe "#replace" do
    it "works" do
      configuration.replace("x" => "y")
      expect(configuration.to_h).to eql("x" => "y")
    end

    it "stringifies keys" do
      configuration.replace(symkey: "ruby")
      expect(configuration.to_h).to eql("symkey" => "ruby")
    end

    it "accepts another Configuration" do
      configuration.replace(described_class.new("ma" => "goo"))
      expect(configuration.to_h).to eql("ma" => "goo")
    end
  end

  describe "#delete" do
    it "works" do
      configuration.delete("key1")
      expect(configuration.to_h).to eql("key2" => "value2")
    end
  end

  describe "#key?" do
    it "works" do
      expect(configuration.key?("key1")).to be true
      expect(configuration.key?("nonexistent")).to be false
    end

    it "stringifies the given key" do
      expect(configuration.key?(:key1)).to be true
    end
  end

  describe "#include?" do
    it "works" do
      expect(configuration.include?("key1")).to be true
      expect(configuration.include?("nonexistent")).to be false
    end

    it "stringifies the given key" do
      expect(configuration.include?(:key1)).to be true
    end
  end
end
