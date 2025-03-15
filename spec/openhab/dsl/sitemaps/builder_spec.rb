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

  it "can reference the items collection" do
    items.build do
      switch_item Switch1
    end

    sitemaps.build do
      sitemap "default", label: "My Residence" do
        text item: items["Switch1"]
      end
    end
  end

  context "with proxy items" do
    it "automatically uses proxy items if the item doesn't exist" do
      sitemaps.build do
        sitemap "default", label: "My Residence" do
          text item: Switch1
        end
      end
    end

    it "works with builder proxy" do
      sitemaps.build do |builder|
        builder.sitemap "default", label: "My Residence" do
          builder.text item: Switch1
        end
      end

      sitemaps.build do
        sitemap "default", label: "My Residence" do |builder|
          builder.text item: Switch1
        end
      end

      sitemaps.build do
        sitemap "default", label: "My Residence" do
          text do |builder|
            builder.switch item: Switch1
          end
        end
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

    it "supports dynamic icons" do
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

  context "with static_icon" do
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
      cond = cond.conditions.first
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
      cond = cond.conditions.first
      expect(cond.item).to be_nil
      expect(cond.condition).to be_nil
      expect(cond.state).to eq "ON"
    end

    it "supports a condition with a literal state" do
      s = sitemaps.build do
        sitemap "default", label: "My Residence" do
          switch item: "Switch1", visibility: ON
        end
      end

      switch = s.children.first
      cond = switch.visibility.first
      cond = cond.conditions.first
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
      cond = cond.conditions.first
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
      cond = cond.conditions.first
      expect(cond.item).to eq "Switch1"
      expect(cond.condition.to_s).to eq "=="
      expect(cond.state).to eq "ON"

      cond = switch.visibility.last
      cond = cond.conditions.first
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
      cond = cond.conditions.first
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
      expect(default.conditions).to be_empty
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
          switch label: "My Switch", mappings: [%w[OFF off], %w[COOL cool f7:snow], %w[HEAT heat f7:flame]]
        end
      end
      switch = sitemaps["default"].children.first
      expect(switch.mappings.map(&:cmd)).to eq %w[OFF COOL HEAT]
      expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
      expect(switch.mappings.map(&:icon)).to eq [nil,
                                                 "f7:snow",
                                                 "f7:flame"]
    end

    it "supports release command in a hash element", if: OpenHAB::Core.version >= OpenHAB::Core::V4_2 do
      sitemaps.build do
        sitemap "default" do
          switch label: "My Switch", mappings: [
            { command: OFF, release: ON, label: "off" }
          ]
        end
      end
      switch = sitemaps["default"].children.first
      expect(switch.mappings.first.cmd).to eq "OFF"
      expect(switch.mappings.first.release_cmd).to eq "ON"
    end

    it "can contain hashes of command, label, and an optional icon" do
      sitemaps.build do
        sitemap "default" do
          switch label: "My Switch", mappings: [
            { command: "OFF", label: "off" },
            { command: "COOL", label: "cool", icon: "f7:snow" },
            { command: "HEAT", label: "heat", icon: "f7:flame" }
          ]
        end
      end
      switch = sitemaps["default"].children.first
      expect(switch.mappings.map(&:cmd)).to eq %w[OFF COOL HEAT]
      expect(switch.mappings.map(&:label)).to eq %w[off cool heat]
      expect(switch.mappings.map(&:icon)).to eq [nil, "f7:snow", "f7:flame"]
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

  describe "#slider" do
    it "works" do
      sitemaps.build do
        sitemap "default" do
          slider label: "My Slider"
        end
      end
    end

    it "supports switch_enabled option" do
      s = sitemaps.build do
        sitemap "default" do
          slider switch: true
        end
      end

      expect(s.children.first.switch_enabled).to be true
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

  it "can add a colortemperaturepicker", if: OpenHAB::Core.version >= OpenHAB::Core::V4_3 do
    sitemaps.build do
      sitemap "default" do
        colortemperaturepicker label: "My Colorpicker"
      end
    end
  end

  describe "#buttongrid" do
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
          ]
        end
      end

      bg = s.children.first
      expect(bg.children.size).to eq 6
      expect(bg.children[0].row).to eq 1
      expect(bg.children[5].cmd).to eq "LEFT"
    end

    it "accepts an array of hashes for buttons parameter" do
      s = sitemaps.build do
        sitemap "default" do
          buttongrid buttons: [
            { row: 1, column: 2, click: "BACK", label: "Back", icon: "f7:return" }
          ]
        end
      end

      bg = s.children.first
      expect(bg.children.size).to eq 1
      expect(bg.children[0].row).to eq 1
      expect(bg.children[0].column).to eq 2
      expect(bg.children[0].cmd).to eq "BACK"
      expect(bg.children[0].label).to eq "Back"
      expect(bg.children[0].icon).to eq "f7:return"
    end

    it "uses the command as label by default" do
      s = sitemaps.build do
        sitemap "default" do
          buttongrid buttons: [[1, 1, "BACK"], [1, 2, "FORWARD", "Forward"]]
        end
      end

      buttons = s.children.first.children
      expect(buttons[0].label).to eq "BACK"
      expect(buttons[1].label).to eq "Forward"
    end

    describe "#button" do
      it "accepts an array of arguments" do
        s = sitemaps.build do
          sitemap "default" do
            buttongrid do
              button [1, 1, "BACK", "Back", "f7:return"]
            end
          end
        end
        button = s.children.first.children.first
        expect(button.row).to eq 1
        expect(button.column).to eq 1
        expect(button.cmd).to eq "BACK"
        expect(button.label).to eq "Back"
        expect(button.icon).to eq "f7:return"
      end

      it "accepts positional arguments" do
        s = sitemaps.build do
          sitemap "default" do
            buttongrid do
              button 1, 1, "BACK", "Back", "f7:return"
            end
          end
        end
        button = s.children.first.children.first
        expect(button.row).to eq 1
        expect(button.column).to eq 1
        expect(button.cmd).to eq "BACK"
        expect(button.label).to eq "Back"
        expect(button.icon).to eq "f7:return"
      end

      it "accepts keyword arguments" do
        s = sitemaps.build do
          sitemap "default" do
            buttongrid do
              button row: 1, column: 1, click: "BACK", label: "Back", icon: "f7:return"
              button row: 1, column: 2, click: "HOME", label: "Menu", icon: "material:apps"
            end
          end
        end

        bg = s.children.first
        buttons = bg.children
        expect(buttons.size).to eq 2
        expect(buttons[0].column).to eq 1
        expect(buttons[1].cmd).to eq "HOME"
      end

      context "when mixing positional and keyword arguments" do
        it "works" do
          sitemaps.build do
            sitemap "default" do
              buttongrid do
                button 1, 1, click: "HOME", label: "Menu", icon: "material:apps"
              end
            end
          end
        end

        it "keyword arguments override positional arguments" do
          s = sitemaps.build do
            sitemap "default" do
              buttongrid do
                button 1, 1, "POS", "Label", "icon", row: 2, column: 2, click: "HOME", label: "Menu", icon: "power"
              end
            end
          end
          bg = s.children.first
          button = bg.children.first
          expect(button.row).to eq 2
          expect(button.column).to eq 2
          expect(button.cmd).to eq "HOME"
          expect(button.label).to eq "Menu"
          expect(button.icon).to eq "power"
        end
      end

      it "adds the buttongrid's buttons argument before the method calls in the block" do
        s = sitemaps.build do
          sitemap "default" do
            buttongrid buttons: [
              [1, 1, "BACK", "Back", "f7:return"]
            ] do
              button row: 1, column: 2, click: "YELLOW", label: "Search", icon: "f7:search"
            end
          end
        end

        bg = s.children.first
        buttons = bg.children
        expect(buttons.size).to eq 2
        expect(buttons[1].row).to eq 1
        expect(buttons[1].column).to eq 2
        expect(buttons[1].cmd).to eq "YELLOW"
      end

      # @deprecated OH 4.1 - remove the if check when dropping OH 4.1 support
      it "uses buttongrid's item by default", if: OpenHAB::Core.version >= OpenHAB::Core::V4_2 do
        items.build do
          string_item Test1
          string_item Test2
        end

        s = sitemaps.build do
          sitemap "default" do
            buttongrid item: Test1 do
              button 1, 1, "FORWARD"
              button 1, 2, "BACK", item: Test2
            end
          end
        end

        buttons = s.children.first.children
        expect(buttons[0].item).to eql "Test1"
        expect(buttons[1].item).to eql "Test2"
      end

      { row: 1, column: 1, click: "CMD" }.tap do |arguments|
        arguments.each_key do |arg|
          it "raises an error when '#{arg}' argument is missing" do
            expect do
              sitemaps.build do
                sitemap "default" do
                  buttongrid do
                    arguments_with_missing_key = arguments.reject { |k, _| k == arg }
                    button(**arguments_with_missing_key)
                  end
                end
              end
            end.to raise_error(ArgumentError)
          end
        end
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
