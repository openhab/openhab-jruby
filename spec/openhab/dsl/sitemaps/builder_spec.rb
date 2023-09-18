# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Sitemaps::Builder do
  after do
    sitemaps.clear
  end

  it "can reference an item directly" do
    items.build do
      switch_item Switch1
    end

    sitemaps.build do
      sitemap "default", "My Residence" do
        text item: Switch1
      end
    end
  end

  it "automatically uses proxy items if the item doesn't exist" do
    sitemaps.build do
      sitemap "default", "My Residence" do
        text item: Switch1
      end
    end
  end

  it "can add a frame" do
    sitemaps.build do
      sitemap "default" do
        frame label: "My Frame" do
          text label: "Dummy Text"
        end
      end
    end
  end

  it "can add a group" do
    sitemaps.build do
      sitemap "default" do
        group label: "My Group" do
          text label: "Dummy Text"
        end
      end
    end
  end

  it "can add an image" do
    sitemaps.build do
      sitemap "default" do
        image label: "My Image" do
          text label: "Dummy Text"
        end
      end
    end
  end

  it "can add a video" do
    sitemaps.build do
      sitemap "default" do
        video label: "My Video"
      end
    end
  end

  it "can add a chart" do
    sitemaps.build do
      sitemap "default" do
        chart label: "My Chart"
      end
    end
  end

  it "can add a webview" do
    sitemaps.build do
      sitemap "default" do
        webview label: "My Web View"
      end
    end
  end

  it "can add a switch" do
    sitemaps.build do
      sitemap "default" do
        switch label: "My Switch"
      end
    end
  end

  it "can add a switch with array mappings" do
    sitemaps.build do
      sitemap "default" do
        switch label: "My Switch", mappings: %w[off cool heat]
      end
    end
    switch = sitemaps["default"].children.first
    expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
    expect(switch.mappings.map(&:cmd)).to eq %w[off cool heat]
  end

  it "can add a switch with hash mappings" do
    sitemaps.build do
      sitemap "default" do
        switch label: "My Switch", mappings: { OFF: "off", COOL: "cool", HEAT: "heat" }
      end
    end
    switch = sitemaps["default"].children.first
    expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
    expect(switch.mappings.map(&:cmd)).to eq %w[OFF COOL HEAT]
  end

  it "can add a mapview" do
    sitemaps.build do
      sitemap "default" do
        mapview label: "My Map View"
      end
    end
  end

  it "can add a slider" do
    sitemaps.build do
      sitemap "default" do
        slider label: "My Slider"
      end
    end
  end

  it "can add a selection" do
    sitemaps.build do
      sitemap "default" do
        selection label: "My Selection"
      end
    end
  end

  it "can add an input" do
    # @deprecated OH 3.4
    skip unless OpenHAB::Core::VERSION >= "4.0.0"

    sitemaps.build do
      sitemap "default" do
        input label: "My Input"
      end
    end
  end

  it "can add a setpoint" do
    sitemaps.build do
      sitemap "default" do
        setpoint label: "My Setpoint"
      end
    end
  end

  it "can add a colorpicker" do
    sitemaps.build do
      sitemap "default" do
        colorpicker label: "My Colorpicker"
      end
    end
  end

  it "can add a default" do
    sitemaps.build do
      sitemap "default" do
        default label: "My Default Widget"
      end
    end
  end
end
