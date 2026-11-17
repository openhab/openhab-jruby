# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Pages::Registry do
  after { OpenHAB::Core::Pages::Provider.instance.clear }

  it "enumerates and removes Ruby pages" do
    page = pages.build { layout_page "ruby_home" }

    expect(pages.to_a).to include(page)
    expect(pages).to be_key("ruby_home")
    expect(pages.remove(page)).to eq page
    expect(pages["ruby_home"]).to be_nil
    expect { pages.remove("ruby_home") }.to raise_error(ArgumentError, /not owned/)
  end

  it "updates owned pages by default and rejects duplicates when updates are disabled" do
    pages.build { layout_page "ruby_home", label: "Before" }
    pages.build { layout_page "ruby_home", label: "After" }

    expect(pages["ruby_home"].config["label"]).to eq "After"
    expect { pages.build(update: false) { layout_page "ruby_home" } }.to raise_error(ArgumentError, /already exists/)
  end

  it "leaves pages owned by other providers untouched" do
    provider_class = OpenHAB::Core::Pages::Provider
    provider_class.new(thread_provider: false) do |other|
      foreign = org.openhab.core.ui.components.RootUIComponent.new("foreign_page", "oh-map-page")
      other.add(foreign)

      expect(pages["foreign_page"]).to eq foreign
      expect { pages.build { layout_page "foreign_page" } }.to raise_error(ArgumentError, /another provider/)
      expect { pages.remove("foreign_page") }.to raise_error(ArgumentError, /not owned/)
      expect(pages["foreign_page"]).to eq foreign
    end

    expect(pages["foreign_page"]).to be_nil
  end

  it "protects pages created through MainUI's persistent provider" do
    persistent = OpenHAB::Core::Pages::Provider.registry.managed_provider
    persistent = persistent.get if persistent.is_a?(java.util.Optional)
    foreign = org.openhab.core.ui.components.RootUIComponent.new("mainui_page", "oh-layout-page")
    persistent.add(foreign)

    expect { pages.build { layout_page "mainui_page" } }.to raise_error(ArgumentError, /another provider/)
    expect { pages.remove("mainui_page") }.to raise_error(ArgumentError, /not owned/)
    expect(pages["mainui_page"]).to eq foreign
  ensure
    persistent&.remove("mainui_page")
  end
end
