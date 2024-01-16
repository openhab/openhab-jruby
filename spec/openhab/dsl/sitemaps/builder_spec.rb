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
      sitemap "default", label: "My Residence" do
        text item: Switch1
      end
    end
  end

  it "automatically uses proxy items if the item doesn't exist" do
    sitemaps.build do
      sitemap "default", label: "My Residence" do
        text item: Switch1
      end
    end
  end

  it "supports receiving a builder argument" do
    example = self
    sitemaps.build do |b|
      expect(self).to be example
      expect(b.__getobj__).to be_a(OpenHAB::DSL::Sitemaps::Builder)
      b.sitemap "default", label: "My Residence" do
        expect(self).to be example
        expect(b.__getobj__).to be_a(OpenHAB::DSL::Sitemaps::SitemapBuilder)
        expect(self).not_to respond_to(:text)
        b.text item: "Switch1"
        expect(self).to be example
        expect(b.__getobj__).to be_a(OpenHAB::DSL::Sitemaps::SitemapBuilder)
        expect(self).not_to respond_to(:text)
        expect { b.text }.not_to raise_error # Call a second time to ensure that builder proxy got reset correctly
      end
    end
  end

  it "supports receiving a builder argument in an inner block" do
    example = self
    sitemaps.build do
      example.expect(self).to example.be_a(OpenHAB::DSL::Sitemaps::Builder)
      sitemap "default", label: "My Residence" do |b|
        example.expect(self).to example.be_a(OpenHAB::DSL::Sitemaps::Builder)
        example.expect(b.__getobj__).to example.be_a(OpenHAB::DSL::Sitemaps::SitemapBuilder)
        example.expect(self).not_to example.respond_to(:text)
        b.text item: "Switch1"
      end
    end
  end

  context "with icon" do
    it "supports a simple icon" do
      s = sitemaps.build do
        sitemap "default" do
          switch item: Switch1, icon: "light"
        end
      end

      switch = s.children.first
      expect(switch.icon).to eq "light"
    end

    it "supports dynamic icons", if: OpenHAB::Core.version >= OpenHAB::Core::V4_1 do
      s = sitemaps.build do
        sitemap "default" do
          switch item: Switch1, icon: { "ON" => "f7:lightbulb_fill", "OFF" => "f7:lightbulb_slash_fill" }
        end
      end

      switch = s.children.first
      expect(switch.icon).to be_nil

      expect(switch.icon_rules.size).to eq 2
      cond = switch.icon_rules.first
      expect(cond.conditions.first.state).to eq "ON"
      expect(cond.arg).to eq "f7:lightbulb_fill"

      cond = switch.icon_rules.last
      expect(cond.conditions.first.state).to eq "OFF"
      expect(cond.arg).to eq "f7:lightbulb_slash_fill"
    end
  end

  context "with static_icon", if: OpenHAB::Core.version >= OpenHAB::Core::V4_1 do
    it "works" do
      s = sitemaps.build do
        sitemap "default" do
          switch item: Switch1, static_icon: "light"
        end
      end

      switch = s.children.first
      expect(switch.static_icon).to eq "light"
    end

    it "is mutually exclusive with icon" do
      expect do
        sitemaps.build do
          sitemap "default" do
            switch item: Switch1, static_icon: "light", icon: "light"
          end
        end
      end.to raise_error(ArgumentError)
    end
  end

  describe "#visibility" do
    it "supports a simple condition" do
      s = sitemaps.build do
        sitemap "default", label: "My Residence" do
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
        sitemap "default", label: "My Residence" do
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
        sitemap "default", label: "My Residence" do
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
        sitemap "default", label: "My Residence" do
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
        sitemap "default", label: "My Residence" do
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
        sitemap "default", label: "My Residence" do
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
        sitemap "default", label: "My Residence" do
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
        sitemap "default", label: "My Residence" do
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
  if OpenHAB::Core.version >= OpenHAB::Core::V4_1
    it "supports AND conditions on visibility" do
      sitemaps.build do
        sitemap "default", label: "My Residence" do
          switch item: "Switch1", visibility: [["Switch1 == ON"]]
        end
      end
    end

    it "supports AND conditions on colors" do
      s = sitemaps.build do
        sitemap "default", label: "My Residence" do
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
          sitemap "default", label: "My Residence" do
            switch item: "Switch1", visibility: [["Switch1 == ON"]]
          end
        end
      end.to raise_error(ArgumentError)
    end

    it "does not support AND conditions on colors" do
      expect do
        sitemaps.build do
          sitemap "default", label: "My Residence" do
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

  context "when adding a switch with array mappings" do
    it "can contain scalar that represent the command and the label" do
      sitemaps.build do
        sitemap "default" do
          switch label: "My Switch", mappings: %w[off cool heat]
        end
      end
      switch = sitemaps["default"].children.first
      expect(switch.mappings.map(&:cmd)).to eq %w[off cool heat]
      expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
    end

    it "can contain arrays of command and label" do
      sitemaps.build do
        sitemap "default" do
          switch label: "My Switch", mappings: [%w[OFF off], %w[COOL cool], %w[HEAT heat]]
        end
      end
      switch = sitemaps["default"].children.first
      expect(switch.mappings.map(&:cmd)).to eq %w[OFF COOL HEAT]
      expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
    end

    it "can contain arrays of command, label, and an optional icon" do
      sitemaps.build do
        sitemap "default" do
          # @deprecated OH 4.1
          if OpenHAB::Core.version >= OpenHAB::Core::V4_1
            switch label: "My Switch", mappings: [%w[OFF off], %w[COOL cool f7:snow], %w[HEAT heat f7:flame]]
          else
            switch label: "My Switch", mappings: [%w[OFF off], %w[COOL cool], %w[HEAT heat]]
          end
        end
      end
      switch = sitemaps["default"].children.first
      expect(switch.mappings.map(&:cmd)).to eq %w[OFF COOL HEAT]
      expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
      # @deprecated OH 4.1 - the if check is not needed in OH4.1+
      if OpenHAB::Core.version >= OpenHAB::Core::V4_1
        expect(switch.mappings.map(&:icon)).to eq [nil,
                                                   "f7:snow",
                                                   "f7:flame"]
      end
    end

    it "can contain hashes of command, label, and an optional icon" do
      sitemaps.build do
        sitemap "default" do
          # @deprecated OH 4.0
          if OpenHAB::Core.version >= OpenHAB::Core::V4_1
            switch label: "My Switch", mappings: [
              { command: "OFF", label: "off" },
              { command: "COOL", label: "cool", icon: "f7:snow" },
              { command: "HEAT", label: "heat", icon: "f7:flame" }
            ]
          else
            switch label: "My Switch", mappings: [
              { command: "OFF", label: "off" },
              { command: "COOL", label: "cool" },
              { command: "HEAT", label: "heat" }
            ]
          end
        end
      end
      switch = sitemaps["default"].children.first
      expect(switch.mappings.map(&:cmd)).to eq %w[OFF COOL HEAT]
      expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
      # @deprecated OH 4.0 - the if check is not needed in OH4.1+
      if OpenHAB::Core.version >= OpenHAB::Core::V4_1
        expect(switch.mappings.map(&:icon)).to eq [nil, "f7:snow", "f7:flame"]
      end
    end

    it "can contain a mix of scalar, arrays, and hashes" do
      sitemaps.build do
        sitemap "default" do
          # @deprecated OH 4.1
          switch label: "My Switch", mappings: [
            "OFF",
            %w[COOL cool],
            { command: "HEAT", label: "heat" }
          ]
        end
      end
      switch = sitemaps["default"].children.first
      expect(switch.mappings.map(&:cmd)).to eq %w[OFF COOL HEAT]
      expect(switch.mappings.map(&:label)).to eq %w[OFF cool heat]
    end
  end

  it "can add a switch with hash mappings" do
    sitemaps.build do
      sitemap "default" do
        switch label: "My Switch", mappings: { OFF: "off", COOL: "cool", HEAT: "heat" }
      end
    end
    switch = sitemaps["default"].children.first
    expect(switch.mappings.map(&:cmd)).to eq %w[OFF COOL HEAT]
    expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
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
    skip unless OpenHAB::Core.version >= OpenHAB::Core::V4_0

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

  # @deprecated OH 4.0 guard is only needed for < OH 4.1
  describe "#buttongrid", if: OpenHAB::Core.version >= OpenHAB::Core::V4_1 do
    it "works" do
      s = sitemaps.build do
        sitemap "default" do
          buttongrid buttons: [
            [1, 1, "BACK", "Back", "f7:return"],
            [1, 2, "HOME", "Menu", "material:apps"],
            [1, 3, "YELLOW", "Search", "f7:search"],
            [2, 2, "UP", "Up", "f7:arrowtriangle_up"],
            [4, 2, "DOWN", "Down", "f7:arrowtriangle_down"],
            [3, 1, "LEFT", "Left", "f7:arrowtriangle_left"]
          ] do
            button [3, 3, "RIGHT", "Right", "f7:arrowtriangle_right"]
            button [3, 2, "ENTER", "Enter"]
          end
        end
      end

      bg = s.children.first
      expect(bg.buttons.size).to eq 8
      expect(bg.buttons[0].row).to eq 1
      expect(bg.buttons[7].cmd).to eq "ENTER"
    end

    it "raises an error when button is incomplete" do
      expect do
        sitemaps.build do
          sitemap "default" do
            buttongrid buttons: [[1, 2, 3]]
          end
        end
      end.to raise_error(ArgumentError)

      expect do
        sitemaps.build do
          sitemap "default" do
            buttongrid do
              button
            end
          end
        end
      end.to raise_error(ArgumentError)

      expect do
        sitemaps.build do
          sitemap "default" do
            buttongrid do
              button [1, 2, 3]
            end
          end
        end
      end.to raise_error(ArgumentError)
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
