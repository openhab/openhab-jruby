# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Sitemaps::Registry do
  describe "#remove" do
    it "passes the sitemap uid to the provider when removing a sitemap object" do
      sitemap = sitemaps.build { sitemap "default" }
      provider = OpenHAB::Core::Sitemaps::Provider.current

      expect(provider).to receive(:remove).with(sitemap.uid).and_call_original

      sitemaps.remove(sitemap)
      expect(sitemaps).not_to have_key(sitemap.uid)
    end
  end
end
