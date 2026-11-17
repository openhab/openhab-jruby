# frozen_string_literal: true

require "json"

RSpec.describe OpenHAB::DSL::Pages::Builder do
  after { OpenHAB::Core::Pages::Provider.instance.clear }

  it "builds a layout with real Java component trees and item references" do
    items.build { switch_item PageLight }
    page = pages.build do
      layout_page "ruby_home", label: "Home", sidebar: true, tags: ["ruby"] do
        block title: "Lighting" do
          grid_row do
            grid_col width: "50" do
              toggle_card item: PageLight, title: "Light"
            end
          end
        end
      end
    end

    expect(page).to be_a(org.openhab.core.ui.components.RootUIComponent)
    expect(page.config.to_h).to include("label" => "Home", "sidebar" => true)
    expect(page.tags.to_a).to eq ["ruby"]
    expect(page.timestamp).not_to be_nil
    block = page.slots["default"].first
    card = block.slots["default"].first.slots["default"].first.slots["default"].first
    expect(card.component).to eq "oh-toggle-card"
    expect(card.config["item"]).to eq "PageLight"
    expect(pages["ruby_home"]).to eq page
  end

  it "preserves explicit and nested config keys and expressions while converting keyword names" do
    page = pages.build do
      page "ruby_home" do
        c "widget:custom",
          action_item: FutureLight,
          action_command: "=items.FutureLight.state === 'ON' ? 'OFF' : 'ON'",
          config: { "my_property" => false, "nullable" => nil },
          action_props: { "my_property" => [FutureLight, { "other_key" => :value }] }
      end
    end

    config = page.slots["default"].first.config
    expect(config["actionItem"]).to eq "FutureLight"
    expect(config["actionCommand"]).to eq "=items.FutureLight.state === 'ON' ? 'OFF' : 'ON'"
    expect(config["my_property"]).to be false
    expect(config).to have_key("nullable")
    expect(config["nullable"]).to be_nil
    expect(config["actionProps"]["my_property"].to_a).to eq ["FutureLight", { "other_key" => "value" }]
  end

  it "supports explicit builder blocks and restores the context after nesting" do
    example = self
    page = pages.build do |b|
      b.layout_page "ruby_home" do
        example.expect(self).to example.equal(example)
        b.block do
          b.grid_row { b.grid_col { b.label_card item: FutureTemperature } }
        end
        b.masonry { b.label_card item: FutureTemperature }
        example.expect(b).to example.respond_to(:grid_row)
        example.expect(b).not_to example.respond_to(:map_marker)
      end
    end

    expect(page.slots["default"].map(&:component)).to eq ["oh-block"]
    expect(page.slots["masonry"].first.component).to eq "oh-masonry"
  end

  it "supports an explicit builder argument introduced inside an implicit block" do
    page = pages.build do
      layout_page "ruby_home" do |b|
        b.block { b.grid_row { b.grid_col { b.label_card item: FutureTemperature } } }
      end
    end

    expect(page.slots["default"].first.component).to eq "oh-block"
  end

  it "automatically places masonry in its layout page slot without moving subsequent children" do
    page = pages.build do
      layout_page "ruby_home" do
        masonry { label_card item: FutureTemperature }
        block title: "After masonry"
        slot("custom") { masonry }
        slot("default") { masonry }
      end
    end

    expect(page.slots["masonry"].first.slots["default"].first.component).to eq "oh-label-card"
    expect(page.slots["default"].first.config["title"]).to eq "After masonry"
    expect(page.slots["custom"].first.component).to eq "oh-masonry"
    expect(page.slots["default"].last.component).to eq "oh-masonry"
  end

  it "passes a builder to slot blocks while retaining their surrounding Ruby self" do
    example = self
    page = pages.build do
      chart_page "ruby_chart" do
        slot "series" do |b|
          example.expect(self).to example.be_a(OpenHAB::DSL::Pages::ChartPageBuilder)
          b.time_series item: FutureTemperature
        end
      end
    end

    expect(page.slots["series"].first.config["item"]).to eq "FutureTemperature"
  end

  it "appends named slots and restores the previous slot after nested blocks" do
    page = pages.build do
      chart_page "ruby_chart" do
        slot "xAxis" do
          time_axis
          slot("yAxis") { value_axis }
          category_axis
        end
        slot("series") { time_series item: FutureTemperature }
        slot("series") { time_series item: FutureHumidity }
      end
    end

    expect(page.slots["xAxis"].map(&:component)).to eq %w[oh-time-axis oh-category-axis]
    expect(page.slots["yAxis"].first.component).to eq "oh-value-axis"
    expect(page.slots["series"].map { |c| c.config["item"] }).to eq %w[FutureTemperature FutureHumidity]
  end

  it "exposes specialized helpers only in the matching page context" do
    example = self
    pages.build do |b|
      b.map_page "ruby_map" do
        b.map_marker item: FutureLocation do
          example.expect(b).not_to example.respond_to(:map_circle_marker, :plan_marker)
          example.expect { b.map_circle_marker }.to example.raise_error(NoMethodError)
        end
        b.map_circle_marker radius: 10
      end
      b.layout_page "ruby_layout" do
        example.expect { b.map_marker item: "Location" }.to example.raise_error(NoMethodError)
        example.expect { b.map_marker }.to example.raise_error(NoMethodError)
        b.chart do
          example.expect(b).to example.respond_to(:time_axis)
          example.expect(b).not_to example.respond_to(:map_marker)
          b.slot("xAxis") { b.time_axis }
        end
        example.expect(b).not_to example.respond_to(:time_axis)
      end
      b.plan_page("ruby_plan") { b.plan_marker coords: "10,20" }
      b.tabs_page("ruby_tabs") { b.tab title: "Map", page: "ruby_map" }
    end

    expect(pages["ruby_map"].component).to eq "oh-map-page"
    expect(pages["ruby_plan"].component).to eq "oh-plan-page"
    expect(pages["ruby_tabs"].slots["default"].first.config["page"]).to eq "ruby_map"
  end

  it "supports the floorplan and tabbed page aliases" do
    pages.build do
      floorplan_page "ruby_plan", image: { url: "/static/plan.png" }
      tabbed_page "ruby_tabs"
    end

    expect(pages["ruby_plan"].config["imageUrl"]).to eq "/static/plan.png"
    expect(pages["ruby_tabs"].component).to eq "oh-tabs-page"
  end

  it "uses specialized page and component builder classes for helper blocks" do
    example = self
    pages.build do |b|
      b.layout_page "ruby_layout" do
        example.expect(b.__getobj__).to example.be_a(OpenHAB::DSL::Pages::LayoutPageBuilder)
        b.block do
          example.expect(b.__getobj__).to example.be_a(OpenHAB::DSL::Pages::LayoutPageBuilder)
          b.grid_row { b.grid_col { b.label_card item: FutureTemperature } }
        end
      end
      b.map_page "ruby_map" do
        example.expect(b.__getobj__).to example.be_a(OpenHAB::DSL::Pages::MapPageBuilder)
        b.map_marker item: FutureLocation do
          example.expect(b.__getobj__.class).to example.eq(OpenHAB::DSL::UI::ComponentBuilder)
          example.expect(b).not_to example.respond_to(:map_marker)
        end
      end
    end
  end

  it "gives generic component blocks only shared helpers regardless of their type or parent" do
    example = self
    pages.build do |b|
      b.map_page "ruby_map" do
        b.c "oh-map-page" do
          example.expect(b.__getobj__.class).to example.eq(OpenHAB::DSL::UI::ComponentBuilder)
          example.expect(b).to example.respond_to(:repeater, :label_card)
          example.expect(b).not_to example.respond_to(:map_marker)
          example.expect { b.map_marker item: "Location" }.to example.raise_error(NoMethodError)
          b.repeater do
            example.expect(b).not_to example.respond_to(:map_marker)
          end
        end
        example.expect(b).to example.respond_to(:map_marker)
      end
      b.layout_page "ruby_layout" do
        b.component "oh-chart" do
          example.expect(b).not_to example.respond_to(:time_axis)
          example.expect(b).not_to example.respond_to(:grid_row)
        end
        b.chart do
          example.expect(b.__getobj__).to example.be_a(OpenHAB::DSL::Pages::ChartPageBuilder)
          b.slot("xAxis") { b.time_axis }
        end
      end
      b.page "ruby_generic", component: "oh-map-page" do
        example.expect(b.__getobj__.class).to example.eq(OpenHAB::DSL::Pages::PageBuilder)
        example.expect(b).not_to example.respond_to(:map_marker)
      end
    end
  end

  it "ends specialized helper contexts at markers, chart elements, and tabs" do
    [%i[map_page map_marker],
     %i[plan_page plan_marker],
     %i[chart_page value_axis],
     %i[tabs_page tab]].each do |page_method, child_method|
      child = nil
      example = self
      page = pages.build do |b|
        b.public_send(page_method, "ruby_#{page_method}") do
          child = b.public_send(child_method) do
            example.expect(b.__getobj__.class).to example.eq(OpenHAB::DSL::UI::ComponentBuilder)
            example.expect(b).to example.respond_to(:label_card)
            example.expect(b).not_to example.respond_to(child_method)
          end
          example.expect(b).to example.respond_to(child_method)
        end
      end

      expect(child).to be_instance_of(OpenHAB::DSL::UI::ComponentBuilder)
      expect(page.slots["default"].first).to be_a(org.openhab.core.ui.components.UIComponent)
    end
  end

  it "exposes Ruby config collections through the Java API and serializes their nested values" do
    page = pages.build do
      layout_page "ruby_config", config: { "nilValue" => nil } do
        c "widget:custom", config: { "values" => [FutureLight, :ON, false, 0, nil, { "nested_key" => "text" }] }
      end
    end

    config = java.util.Collections.unmodifiable_map(page.getConfig)
    expect(config.get("nilValue")).to be_nil
    component = page.getSlot("default").get(0)
    values = java.util.Collections.unmodifiable_list(java.util.Collections.unmodifiable_map(component.getConfig)
                                                        .get("values"))
    expect(values.get(0)).to eq "FutureLight"
    expect(values.get(2)).to be false
    expect(java.util.Collections.unmodifiable_map(values.get(5)).get("nested_key")).to eq "text"
    json = JSON.parse(com.google.gson.Gson.new.to_json(page))
    expect(json["slots"]["default"].first["config"]["values"])
      .to eq ["FutureLight", "ON", false, 0, nil, { "nested_key" => "text" }]
  end

  it "serializes nested configuration and slots as MainUI JSON" do
    page = pages.build do
      map_page "ruby_map", initial: { zoom: 8 }, no_zoom_or_drag: false do
        map_marker item: FutureLocation, config: { "actionProps" => { "custom_property" => [1, true, nil] } }
      end
    end

    json = JSON.parse(com.google.gson.Gson.new.to_json(page))
    expect(json).to include("uid" => "ruby_map", "component" => "oh-map-page")
    expect(json["config"]).to include("initialZoom" => 8, "noZoomOrDrag" => false)
    marker = json["slots"]["default"].first
    expect(marker["config"]).to include("item" => "FutureLocation",
                                        "actionProps" => { "custom_property" => [1, true, nil] })
  end

  it "restores proxy and slot contexts after exceptions" do
    example = self
    page = pages.build do |b|
      b.layout_page "ruby_home" do
        example.expect do
          b.slot "masonry" do
            b.masonry { raise "failed child" }
          end
        end.to example.raise_error("failed child")
        b.block title: "After failure"
      end
    end

    expect(page.slots["default"].first.config["title"]).to eq "After failure"
    expect(page.slots["masonry"]).to be_empty
  end

  it "keeps an existing page when rebuilding fails" do
    original = pages.build { layout_page "ruby_home", label: "Original" }
    expect do
      pages.build { layout_page("ruby_home") { raise "failed rebuild" } }
    end.to raise_error("failed rebuild")

    expect(pages["ruby_home"]).to eq original
  end

  it "rejects an empty UID" do
    expect { pages.build { page "" } }.to raise_error(ArgumentError, /UID/)
  end

  it "rejects unknown keywords on built-in page and component helpers" do
    expect { pages.build { layout_page "ruby_home", unknown_option: true } }
      .to raise_error(ArgumentError, /unknown keyword/)
    expect { pages.build { layout_page("ruby_home") { toggle_card unknown_option: true } } }
      .to raise_error(ArgumentError, /unknown keyword/)
  end

  it "preserves explicit configuration while omitting nil helper keywords and retaining false" do
    page = pages.build do
      layout_page "ruby_home",
                  label: nil,
                  sidebar: false,
                  config: { "label" => "Before", "sidebar" => true, "icon" => "house", "nullable" => nil } do
        toggle_card item: FutureLight, title: nil, config: { "title" => "Before", "custom" => false }
      end
    end

    expect(page.config.to_h).to eq("label" => "Before", "sidebar" => false, "icon" => "house", "nullable" => nil)
    expect(page.slots["default"].first.config.to_h)
      .to eq("item" => "FutureLight", "title" => "Before", "custom" => false)
  end

  it "maps built-in keywords to exact MainUI property names, including reserved Ruby words" do
    page = pages.build do
      layout_page "ruby_home" do
        repeater for: "entry", in: [1, 2] do
          button taphold_action: { value: "command", item: FutureLight }
        end
      end
    end

    repeater = page.slots["default"].first
    expect(repeater.config["for"]).to eq "entry"
    expect(repeater.config["in"].to_a).to eq [1, 2]
    expect(repeater.slots["default"].first.config.to_h)
      .to eq("taphold_action" => "command", "taphold_actionItem" => "FutureLight")
  end

  it "flattens grouped options into MainUI configuration without flattening payload hashes" do
    page = pages.build do
      plan_page "ruby_plan", image: { url: "/static/plan.png", width: 1000, height: 600 } do
        plan_marker icon: { value: "f7:lightbulb", size: 24, width: 36 },
                    tooltip: { value: "Light", font_size: "12px", color: "blue", permanent: false, as_label: true },
                    action: { value: "command",
                              item: FutureLight,
                              command: "ON",
                              modal_config: { "my_property" => [1, true] } }
      end
    end

    expect(page.config.to_h).to eq("imageUrl" => "/static/plan.png", "imageWidth" => 1000, "imageHeight" => 600)
    marker = page.slots["default"].first
    expect(marker.config.to_h).to include("icon" => "f7:lightbulb",
                                          "iconSize" => 24,
                                          "iconWidth" => 36,
                                          "tooltip" => "Light",
                                          "tooltipFontSize" => "12px",
                                          "tooltipColor" => "blue",
                                          "tooltipPermanent" => false,
                                          "useTooltipAsLabel" => true,
                                          "action" => "command",
                                          "actionItem" => "FutureLight",
                                          "actionCommand" => "ON")
    expect(marker.config["actionModalConfig"]["my_property"].to_a).to eq [1, true]
  end

  it "accepts scalar group values and omits nil details while retaining explicit raw configuration" do
    page = pages.build do
      plan_page "ruby_plan" do
        plan_marker icon: "f7:lightbulb", tooltip: "Light", action: "toggle"
        plan_marker tooltip: { color: nil, permanent: false }, config: { "tooltipColor" => "red" }
      end
    end

    expect(page.slots["default"].first.config.to_h)
      .to eq("icon" => "f7:lightbulb", "tooltip" => "Light", "action" => "toggle")
    expect(page.slots["default"].last.config.to_h).to eq("tooltipColor" => "red", "tooltipPermanent" => false)
  end

  it "rejects flat detailed keywords and unknown grouped options" do
    expect { pages.build { plan_page("ruby_plan") { plan_marker tooltip_color: "red" } } }
      .to raise_error(ArgumentError, /unknown keyword/)
    expect { pages.build { plan_page("ruby_plan") { plan_marker tooltip: { unknown: true } } } }
      .to raise_error(ArgumentError, /Unknown tooltip option/)
    expect { pages.build { plan_page("ruby_plan") { plan_marker zoom_visibility: 10 } } }
      .to raise_error(ArgumentError, /zoom_visibility must be a Hash/)
  end

  it "supports string hash keys, detail-only groups, and scalar values whose base follows its details" do
    page = pages.build do
      map_page "ruby_map", initial: { "center" => "1,2", "zoom" => 8 } do
        map_circle_marker radius: { value: 10, item: FutureRadius }
        map_circle_marker radius: 20
      end
    end

    expect(page.config.to_h).to eq("initialCenter" => "1,2", "initialZoom" => 8)
    expect(page.slots["default"].first.config.to_h).to eq("radius" => 10, "radiusItem" => "FutureRadius")
    expect(page.slots["default"].last.config["radius"]).to eq 20
  end
end
