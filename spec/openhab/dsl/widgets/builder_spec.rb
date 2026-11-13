# frozen_string_literal: true

require "json"

RSpec.describe OpenHAB::DSL::Widgets::Builder do
  after do
    OpenHAB::Core::Widgets::Provider.instance.clear
    OpenHAB::Core::Pages::Provider.instance.clear
  end

  it "builds a reusable widget with the component itself as its root and a MainUI property schema" do
    widget = widgets.build do
      widget "ruby_light", tags: [:lighting] do
        props do
          parameter :light_item, :text, label: "Light", context: "item", required: true
          group :appearance, label: "Appearance" do
            parameter :title, :text, label: "Title", default: "My light"
          end
        end
        toggle_card item: "=props.light_item", title: "=props.title"
      end
    end

    expect(widget).to be_a(org.openhab.core.ui.components.RootUIComponent)
    expect(widget.uid).to eq "ruby_light"
    expect(widget.component).to eq "oh-toggle-card"
    expect(widget.config).to include("item" => "=props.light_item", "title" => "=props.title")
    expect(widget.tags.to_a).to eq ["lighting"]
    expect(widget.timestamp).not_to be_nil
    json = JSON.parse(com.google.gson.Gson.new.to_json(widget))
    expect(json["props"]["parameters"]).to include(
      include("name" => "light_item", "type" => "TEXT", "context" => "item", "required" => true),
      include("name" => "title", "groupName" => "appearance", "default" => "My light")
    )
    expect(json["props"]["parameterGroups"]).to include(include("name" => "appearance", "label" => "Appearance"))
    expect(json["props"]).not_to have_key("uri")
  end

  it "builds a generic root with named slots and references another widget from pages" do
    widget = widgets.build do
      widget "ruby_container" do
        c "f7-card", config: { "style" => { "font-size" => "12px" } } do
          slot("header") { c "span", content: "Header" }
          slot("content") { widget "another_widget", config: { "my_prop" => FutureLight } }
        end
      end
    end
    page = pages.build do
      layout_page "ruby_widgets" do
        masonry { widget "ruby_container", config: { "my_prop" => FutureLight } }
      end
    end

    expect(widget.component).to eq "f7-card"
    expect(widget.slots["header"].first.config["content"]).to eq "Header"
    expect(widget.slots["content"].first.config["my_prop"]).to eq "FutureLight"
    expect(widget.config["style"]).to eq("font-size" => "12px")
    expect(page.slots["masonry"].first.slots["default"].first.component).to eq "widget:ruby_container"
    expect(widget.props.parameters).to be_empty
    expect(widget.props.parameterGroups).to be_empty
  end

  it "retains the enclosing Ruby self and restores proxies across properties, groups, and components" do
    example = self
    widget = widgets.build do |b|
      b.widget "ruby_light" do
        example.expect(self).to example.equal(example)
        b.props do
          example.expect(b.__getobj__).to example.be_a(OpenHAB::DSL::Widgets::PropertiesBuilder)
          b.group :appearance do
            example.expect(self).to example.equal(example)
            b.parameter :title, :text, default: "Light"
          end
          b.parameter :light_item, :text, context: "item"
        end
        example.expect(b.__getobj__).to example.be_a(OpenHAB::DSL::Widgets::WidgetBuilder)
        b.card do
          b.slot "default" do
            b.toggle item: "=props.light_item"
          end
        end
      end
    end

    expect(widget.component).to eq "oh-card"
    expect(widget.props.parameters.map(&:name)).to eq %w[title light_item]
    expect(widget.props.parameters.first.groupName).to eq "appearance"
    expect(widget.props.parameters.last.groupName).to be_nil
    expect(widget.slots["default"].first.config["item"]).to eq "=props.light_item"
  end

  it "supports explicit builder arguments introduced at the widget, properties, and group levels" do
    widget = widgets.build do
      widget "ruby_light" do |w|
        w.props do |p|
          p.group :appearance do |g|
            g.parameter :title, :text
          end
        end
        w.label_card item: FutureLight, title: "=props.title"
      end
    end

    expect(widget.props.parameters.first.groupName).to eq "appearance"
    expect(widget.config["item"]).to eq "FutureLight"
  end

  it "accepts an action property group without parameters and appends repeated props blocks" do
    widget = widgets.build do
      widget "ruby_action" do
        props { group :control, context: "action", label: "Control" }
        props { group :appearance, label: "Appearance" }
        button text: "Run"
      end
    end

    expect(widget.props.parameters).to be_empty
    expect(widget.props.parameterGroups.map(&:name)).to eq %w[control appearance]
    expect(widget.props.parameterGroups.first.context).to eq "action"
  end

  it "preserves parameter types, constraints, options, and filter criteria" do
    widget = widgets.build do
      widget "ruby_settings" do
        props do
          parameter :setpoint, :decimal, min: 10, max: 30, step: 0.5, unit: "°C", default: "20"
          parameter :mode, :text, options: { "heat" => "Heat", "cool" => "Cool" }, limit_to_options: true
          parameter :light, :text, context: "item", filter_criteria: { "type" => "Switch" }
          parameter :enabled, :boolean, advanced: true
        end
        c "div"
      end
    end

    json = JSON.parse(com.google.gson.Gson.new.to_json(widget))
    parameters = json["props"]["parameters"]
    expect(parameters[0]).to include("type" => "DECIMAL", "min" => 10, "max" => 30, "step" => 0.5, "unit" => "°C")
    expect(parameters[1]["options"]).to eq [{ "value" => "heat", "label" => "Heat" },
                                            { "value" => "cool", "label" => "Cool" }]
    expect(parameters[2]["filterCriteria"]).to eq [{ "name" => "type", "value" => "Switch" }]
    expect(parameters[3]).to include("type" => "BOOLEAN", "advanced" => true)
  end

  it "supports an embedded chart before any page has been built" do
    widget = widgets.build do
      widget "ruby_chart" do
        chart do
          slot("xAxis") { time_axis }
          slot("series") { time_series item: "=props.item" }
        end
      end
    end

    expect(widget.component).to eq "oh-chart"
    expect(widget.slots["xAxis"].first.component).to eq "oh-time-axis"
    expect(widget.slots["series"].first.config["item"]).to eq "=props.item"
  end

  it "requires exactly one root component and leaves the old widget intact on a failed rebuild" do
    original = widgets.build { widget("ruby_light") { toggle_card item: FutureLight } }

    expect { widgets.build { widget "ruby_empty" } }.to raise_error(ArgumentError, /exactly one root/)
    expect do
      widgets.build do
        widget("ruby_light") do
          toggle
          toggle
        end
      end
    end.to raise_error(ArgumentError, /exactly one root/)
    expect { widgets.build { widget("ruby_header") { slot("header") { label_card } } } }
      .to raise_error(ArgumentError, /exactly one root/)
    expect(widgets["ruby_light"]).to eq original
    expect(widgets["ruby_empty"]).to be_nil
  end

  it "rejects duplicate property and group names" do
    expect do
      widgets.build do
        widget "ruby_bad" do
          props { parameter :title, :text }
          props { parameter :title, :text }
          c "div"
        end
      end
    end.to raise_error(ArgumentError, /Duplicate widget property names: title/)
    expect do
      widgets.build do
        widget "ruby_bad" do
          props do
            group :appearance
            group :appearance
          end
          c "div"
        end
      end
    end.to raise_error(ArgumentError, /Duplicate widget property group names: appearance/)
  end

  it "restores property group and proxy context after a rescued nested group error" do
    example = self
    widget = widgets.build do |b|
      b.widget "ruby_light" do
        b.props do
          b.group :appearance do
            example.expect { b.group :nested }.to example.raise_error(ArgumentError, /cannot be nested/)
            b.parameter :title, :text
          end
          b.parameter :item, :text
        end
        b.toggle_card item: "=props.item"
      end
    end

    expect(widget.props.parameters.first.groupName).to eq "appearance"
    expect(widget.props.parameters.last.groupName).to be_nil
  end

  it "rejects an empty UID" do
    expect { widgets.build { widget "" } }.to raise_error(ArgumentError, /UID/)
  end
end
