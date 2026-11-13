# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Widgets::Registry do
  after do
    OpenHAB::Core::Widgets::Provider.instance.clear
    OpenHAB::Core::Pages::Provider.instance.clear
  end

  it "enumerates widgets and removes only widgets owned by this script" do
    widget = widgets.build { widget("ruby_light") { toggle_card } }

    expect(widgets.to_a).to include(widget)
    expect(widgets).to be_key("ruby_light")
    expect(widgets.remove(widget)).to eq widget
    expect(widgets["ruby_light"]).to be_nil
    expect { widgets.remove("ruby_light") }.to raise_error(ArgumentError, /not owned/)
  end

  it "updates widgets by default and rejects duplicates with updates disabled" do
    widgets.build { widget("ruby_light") { label_card title: "Before" } }
    widgets.build { widget("ruby_light") { label_card title: "After" } }

    expect(widgets["ruby_light"].config["title"]).to eq "After"
    expect { widgets.build(update: false) { widget("ruby_light") { label_card } } }
      .to raise_error(ArgumentError, /already exists/)
  end

  it "keeps page and widget namespaces independent" do
    page = pages.build { layout_page "ruby_home", label: "Home" }
    widget = widgets.build { widget("ruby_home") { toggle_card } }

    expect(pages["ruby_home"]).to eq page
    expect(widgets["ruby_home"]).to eq widget
    widgets.remove(widget)
    expect(pages["ruby_home"]).to eq page
  end

  it "protects widgets owned by another provider and unregisters temporary providers" do
    OpenHAB::Core::Widgets::Provider.new(thread_provider: false) do |other|
      foreign = org.openhab.core.ui.components.RootUIComponent.new("foreign_widget", "oh-card")
      other.add(foreign)

      expect(widgets["foreign_widget"]).to eq foreign
      expect { widgets.build { widget("foreign_widget") { card } } }.to raise_error(ArgumentError, /another provider/)
      expect { widgets.remove("foreign_widget") }.to raise_error(ArgumentError, /not owned/)
    end

    expect(widgets["foreign_widget"]).to be_nil
  end

  it "protects widgets created through MainUI's persistent provider" do
    persistent = OpenHAB::Core::Widgets::Provider.registry.managed_provider
    persistent = persistent.get if persistent.is_a?(java.util.Optional)
    foreign = org.openhab.core.ui.components.RootUIComponent.new("mainui_widget", "oh-card")
    persistent.add(foreign)

    expect { widgets.build { widget("mainui_widget") { card } } }.to raise_error(ArgumentError, /another provider/)
    expect { widgets.remove("mainui_widget") }.to raise_error(ArgumentError, /not owned/)
    expect(widgets["mainui_widget"]).to eq foreign
  ensure
    persistent&.remove("mainui_widget")
  end
end
