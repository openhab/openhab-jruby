# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Sitemaps::Provider do
  let(:model_listener) { org.openhab.core.model.core.ModelRepositoryChangeListener.impl { nil } }
  let(:provider) { described_class.instance }

  before { provider.addModelChangeListener(model_listener) }
  after { provider.removeModelChangeListener(model_listener) }

  describe "#add" do
    it "notifies listeners with the correct name" do
      allow(model_listener).to receive(:modelChanged)

      sitemaps.build do
        sitemap "test"
      end

      expect(model_listener).to have_received(:modelChanged)
        .with("test.sitemap", org.openhab.core.model.core.EventType::ADDED)

      expect(model_listener).to have_received(:modelChanged)
        .with("test.sitemap", org.openhab.core.model.core.EventType::MODIFIED)
    ensure
      sitemaps.remove("test")
    end
  end

  describe "#update" do
    it "notifies listeners with the correct name" do
      sitemaps.build do
        sitemap "test"
      end

      expect(model_listener).not_to receive(:modelChanged)
        .with("test.sitemap", org.openhab.core.model.core.EventType::ADDED)

      expect(model_listener).to receive(:modelChanged)
        .with("test.sitemap", org.openhab.core.model.core.EventType::MODIFIED)

      sitemaps.build(update: true) do
        sitemap "test"
      end
    ensure
      sitemaps.remove("test")
    end
  end

  describe "#remove" do
    it "notifies listeners with the correct name" do
      sitemaps.build do
        sitemap "test"
      end

      expect(model_listener).to receive(:modelChanged)
        .with("test.sitemap", org.openhab.core.model.core.EventType::REMOVED)

      provider.remove("test")
    end
  end
end
