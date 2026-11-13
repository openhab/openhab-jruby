# frozen_string_literal: true

require "tempfile"

RSpec.describe "Rule source metadata" do
  def source_metadata(rule)
    rule.actions.first.configuration["script"]
  end

  def evaluate_file(source)
    Tempfile.create(["rule_source", ".rb"], OpenHAB::Core.config_folder.to_s) do |file|
      file.write(source)
      file.flush
      yield eval(source, binding, file.path), File.basename(file.path) # rubocop:disable Security/Eval
    end
  end

  %i[rule script scene].each do |type|
    describe "##{type}" do
      let(:definition) do
        body = (type == :rule) ? "every :day\n  run { nil }" : "nil"
        "#{type}(id: 'source_test') do\n  #{body}\nend\n"
      end

      it "includes the relative file path, line number, preceding comments, and definition" do
        comments = "# Explain the automation.\n# Keep this context in MainUI."

        evaluate_file("\n#{comments}\n#{definition}") do |rule, filename|
          expect(source_metadata(rule)).to eq "# Source: #{filename}:4\n#{comments}\n#{definition}"
        end
      end

      it "does not add an empty comment section when there are no comments" do
        evaluate_file(definition) do |rule, filename|
          expect(source_metadata(rule)).to eq "# Source: #{filename}:1\n#{definition}"
        end
      end

      it "ignores whitespace before the definition" do
        evaluate_file("  \n\t\n#{definition}") do |rule, filename|
          expect(source_metadata(rule)).to eq "# Source: #{filename}:3\n#{definition}"
        end
      end

      it "preserves an explicitly supplied script" do
        source = definition.sub("id: 'source_test'", "id: 'source_test', script: 'custom source'")

        evaluate_file(source) do |rule, _filename|
          expect(source_metadata(rule)).to eq "custom source"
        end
      end

      it "still creates the rule when its source cannot be read" do
        rule = eval(definition, binding, "missing_rule_source.rb") # rubocop:disable Security/Eval

        expect(rule).not_to be_nil
        expect(source_metadata(rule)).to be_nil
      end
    end
  end

  context "with a UI script" do
    around do |example|
      original_context = $ctx
      $ctx = { "ruleUID" => "ui_source" }
      example.run
    ensure
      $ctx = original_context
    end

    it "reads the definition and comments from the UI rule and includes its UID" do
      source = "# Created in MainUI.\nscript(id: 'nested_script') do\n  nil\nend\n"
      script(id: "ui_source", script: source) { nil }

      rule = eval(source, binding, "<script>") # rubocop:disable Security/Eval

      expect(source_metadata(rule)).to eq "# Source: script:ui_source:2\n#{source}"
    end

    it "still creates the rule when the UI rule cannot be found" do
      rule = eval("script(id: 'nested_script') { nil }", binding, "<script>") # rubocop:disable Style/EvalWithLocation

      expect(rule).not_to be_nil
      expect(source_metadata(rule)).to be_nil
    end
  end
end
