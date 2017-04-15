require "spec_helper"
require "puppetbox/nodeset"

RSpec.describe PuppetBox::NodeSet do
  it "parses good nodeset correctly" do
    nodeset = PuppetBox::NodeSet.parse(NODESET_GOOD)
    expect(nodeset.has_key?('CentOS-7.2-64')).to be true
  end

  it "detects invalid version" do
    expect{PuppetBox::NodeSet.parse(NODESET_INVALID_VERSION)}.to raise_error /version/i
  end

  it "detects invalid version" do
    expect{PuppetBox::NodeSet.parse(NODESET_MISSING_CONFIG)}.to raise_error /config/i
  end

  it "detects invalid version" do
    expect{PuppetBox::NodeSet.parse(NODESET_MISSING_DRIVER)}.to raise_error /driver/i
  end

  it "detects broken file" do
    expect{PuppetBox::NodeSet.parse(NODESET_BROKEN)}.to raise_error /syntax/i
  end

  it "detects missing file" do
    expect{PuppetBox::NodeSet.parse("/not/here")}.to raise_error /not found/i
  end
end
