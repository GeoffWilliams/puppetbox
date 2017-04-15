require "spec_helper"
require "puppetbox/nodeset"

RSpec.describe PuppetBox::NodeSet do
  it "parses good nodeset correctly" do
    nodeset = PuppetBox::NodeSet.new(NODESET_GOOD)
    expect(nodeset.has_node?(NODE_GOOD)).to be true
  end

  it "detects missing nodes correctly" do
    nodeset = PuppetBox::NodeSet.new(NODESET_GOOD)
    expect(nodeset.has_node?('nothere')).to be false
  end

  it "get_node returns requested nodes correctly" do
    nodeset = PuppetBox::NodeSet.new(NODESET_GOOD)
    expect(nodeset.get_node(NODE_GOOD).class).to be Hash
  end

  it "get_node raises when requested node not defined in nodeset" do
    nodeset = PuppetBox::NodeSet.new(NODESET_GOOD)
    expect{nodeset.get_node('nothere')}.to raise_error /not defined/
  end

  it "detects invalid version" do
    expect{PuppetBox::NodeSet.new(NODESET_INVALID_VERSION)}.to raise_error /version/i
  end

  it "detects invalid missing config element" do
    expect{PuppetBox::NodeSet.new(NODESET_MISSING_CONFIG)}.to raise_error /config/i
  end

  it "detects invalid missing driver element" do
    expect{PuppetBox::NodeSet.new(NODESET_MISSING_DRIVER)}.to raise_error /driver/i
  end

  it "detects broken file" do
    expect{PuppetBox::NodeSet.new(NODESET_BROKEN)}.to raise_error /syntax/i
  end

  it "detects missing file" do
    expect{PuppetBox::NodeSet.new("/not/here")}.to raise_error /not found/i
  end

  it "detects missing nodes element" do
    expect{PuppetBox::NodeSet.new(NODESET_MISSING_NODES)}.to raise_error /missing root element/i
  end
end
