# frozen_string_literal: true

RSpec.describe OpenHAB::Core::ProfileFactory do
  it "removes its unload hook when explicitly unregistered" do
    hooks = OpenHAB::Core::ScriptHandlingCallbacks.script_unloaded_hooks[0]
    original_hooks = hooks.dup
    factory = described_class.send(:new)

    expect(hooks.size).to eq(original_hooks.size + 1)

    factory.unregister

    expect(hooks).to eq(original_hooks)
  end
end
