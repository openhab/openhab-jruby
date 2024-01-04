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

  describe "#visibility" do
    it "supports a simple condition" do
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

    it "supports a condition with just the state" do
      s = sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1", visibility: "ON"
        end
      end

      switch = s.children.first
      cond = switch.visibility.first
      # @deprecated OH 4.0
      cond = cond.conditions.first if cond.respond_to?(:conditions)
      expect(cond.item).to be_nil
      expect(cond.condition).to be_nil
      expect(cond.state).to eq "ON"
    end

    it "supports a condition with operator and state" do
      s = sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1", visibility: "==ON"
        end
      end

      switch = s.children.first
      cond = switch.visibility.first
      # @deprecated OH 4.0
      cond = cond.conditions.first if cond.respond_to?(:conditions)
      expect(cond.item).to be_nil
      expect(cond.condition.to_s).to eq "=="
      expect(cond.state).to eq "ON"
    end

    it "supports multiple conditions" do
      s = sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1", visibility: ["Switch1 == ON", "Switch2 == ON"]
        end
      end

      switch = s.children.first

      expect(switch.visibility.size).to eq 2

      cond = switch.visibility.first
      # @deprecated OH 4.0
      cond = cond.conditions.first if cond.respond_to?(:conditions)
      expect(cond.item).to eq "Switch1"
      expect(cond.condition.to_s).to eq "=="
      expect(cond.state).to eq "ON"

      cond = switch.visibility.last
      # @deprecated OH 4.0
      cond = cond.conditions.first if cond.respond_to?(:conditions)
      expect(cond.item).to eq "Switch2"
      expect(cond.condition.to_s).to eq "=="
      expect(cond.state).to eq "ON"
    end
  end

  context "with colors" do
    it "supports conditions" do
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

    it "supports conditions with default value" do
      s = sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1", label_color: { "Switch1 == ON" => "green", :default => "red" }
        end
      end

      switch = s.children.first
      rules = switch.label_color
      expect(rules.size).to eq 2

      default = rules.last
      # @deprecated OH 4.0
      if default.respond_to?(:conditions)
        expect(default.conditions).to be_empty
      else
        expect(default.condition.to_s).to be_empty
      end
      expect(default.arg).to eq "red"
    end

    it "supports non-conditional string value" do
      s = sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1", label_color: "red"
        end
      end

      switch = s.children.first
      expect(switch.label_color.size).to eq 1
      rule = switch.label_color.first
      expect(rule.arg).to eq "red"
    end

    it "supports simple color as the default in multiple calls" do
      s = sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1" do
            label_color "red" # The default doesn't have to be specified last
            label_color "Switch1 == ON" => "green"
          end
        end
      end

      switch = s.children.first
      expect(switch.label_color.first.arg).to eq "green"
      expect(switch.label_color.last.arg).to eq "red"
    end
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
      s = sitemaps.build do
        sitemap "default", "My Residence" do
          switch item: "Switch1", label_color: { ["Switch1 == ON", "Switch2 == OFF"] => "green" }
        end
      end

      switch = s.children.first
      rule = switch.label_color.first
      cond = rule.conditions.first
      expect(cond.item).to eq "Switch1"
      expect(cond.condition.to_s).to eq "=="
      expect(cond.state).to eq "ON"

      cond = rule.conditions.last
      expect(cond.item).to eq "Switch2"
      expect(cond.condition.to_s).to eq "=="
      expect(cond.state).to eq "OFF"
      expect(rule.arg).to eq "green"
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
            switch item: "Switch1", label_color: { ["Switch1 == ON", "Switch2 == OFF"] => "green" }
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
