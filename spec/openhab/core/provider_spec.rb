# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Provider do
  describe "temporary provider cleanup" do
    it "removes unload hooks when block providers are unregistered" do
      hooks = OpenHAB::Core::ScriptHandlingCallbacks.script_unloaded_hooks
      original_hooks = hooks.transform_values(&:dup)

      [OpenHAB::Core::Items::Provider,
       OpenHAB::Core::Items::Metadata::Provider,
       OpenHAB::Core::Items::Semantics::Provider,
       OpenHAB::Core::Rules::Provider,
       OpenHAB::Core::Sitemaps::Provider,
       OpenHAB::Core::Things::Provider,
       OpenHAB::Core::Things::Links::Provider].each do |klass|
        klass.new { |_provider| nil }
      end

      expect(hooks).to eq(original_hooks)
    end
  end
end
