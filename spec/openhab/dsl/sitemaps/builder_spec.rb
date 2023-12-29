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

  it "supports visibility" do
    s = sitemaps.build do
      sitemap "default", "My Residence" do
        switch item: "Switch1", visibility: "Switch1 == ON"
      end
    end

    switch = s.children.first
    cond = switch.visibility.first
    # @deprecated OH 4.0
    cond = cond.conditions.first if cond.respond_to?(:conditions)
    expect(cond.item).to eq "Switch1"
    expect(cond.condition.to_s).to eq "=="
    expect(cond.state).to eq "ON"
  end

  it "supports colors" do
    s = sitemaps.build do
      sitemap "default", "My Residence" do
        switch item: "Switch1", label_color: { "Switch1 == ON" => "green" }
      end
    end

    switch = s.children.first
    cond = rule = switch.label_color.first
    # @deprecated OH 4.0
    cond = cond.conditions.first if cond.respond_to?(:conditions)
    expect(cond.item).to eq "Switch1"
    expect(cond.condition.to_s).to eq "=="
    expect(cond.state).to eq "ON"
    expect(rule.arg).to eq "green"
  end

  # @deprecated OH 4.0
  if Gem::Version.new(OpenHAB::Core::VERSION) >= Gem::Version.new("4.1.0") ||
     OpenHAB::Core::VERSION.start_with?("4.1.0.M")
    it "supports AND conditions on visibility" do
      sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1", visibility: [["Switch1 == ON"]]
        end
      end
    end

    it "supports AND conditions on colors" do
      sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1", label_color: { [["Switch1 == ON", "Switch2 == OFF"]] => "green" }
        end
      end
    end
  else
    it "does not support AND conditions on visibility" do
      expect do
        sitemaps.build do
          sitemap "default", "My Residence" do
            switch item: "Switch1", visibility: [["Switch1 == ON"]]
          end
        end
      end.to raise_error(ArgumentError)
    end

    it "does not support AND conditions on colors" do
      expect do
        sitemaps.build do
          sitemap "default", "My Residence" do
            switch item: "Switch1", label_color: { [["Switch1 == ON", "Switch2 == OFF"]] => "green" }
          end
        end
      end.to raise_error(ArgumentError)
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

  context "when redefining a sitemap" do
    it "with update: false, complains if you try to create a sitemap with the same name" do
      sitemaps.build(update: false) { sitemap "default" }
      expect { sitemaps.build(update: false) { sitemap "default" } }.to raise_error(ArgumentError)
    end

    it "allows you to redefine a sitemap with the same name by default" do
      sitemaps.build { sitemap "default" }
      sitemaps.build { sitemap "default" }
    end
  end
end