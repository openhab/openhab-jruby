# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::ImageItem do
  subject(:item) { items.build { image_item "Image1" } }

  let(:image_base64) do
    "data:image/png;base64," \
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAA" \
      "XRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII="
  end

  it "is an image" do
    expect(item).to be_an_image_item
  end

  it "is not a group" do
    expect(item).not_to be_a_group_item
  end

  it "provides access to underlying raw type" do
    item.update(image_base64)
    expect(item.state.mime_type).to eql "image/png"
    expect(item.state.bytesize).to be 95
  end

  it "can be updated from a byte array with mime type" do
    item.update_from_bytes(File.binread(fixture("1x1.png")), mime_type: "image/png")
    expect(item.state.mime_type).to eql "image/png"
    expect(item.state.bytesize).to be 95
  end

  it "can be updated from a byte array" do
    item.update_from_bytes(File.binread(fixture("1x1.png")))
    expect(item.state.mime_type).to eql "image/png"
    expect(item.state.bytesize).to be 95
  end

  it "can be updated from a file with mime type" do
    item.update_from_file(fixture("1x1.png"), mime_type: "image/png")
    expect(item.state.mime_type).to eql "image/png"
    expect(item.state.bytesize).to be 95
  end

  it "can be updated from a file" do
    item.update_from_file(fixture("1x1.png"))
    expect(item.state.mime_type).to eql "image/png"
    expect(item.state.bytesize).to be 95
  end

  it "can be updated from a URL" do
    item.update_from_url("https://raw.githubusercontent.com/boc-tothefuture/openhab-jruby/main/features/assets/1x1.png")
    expect(item.state.mime_type).to eql "image/png"
    expect(item.state.bytesize).to be 95
  end
end
