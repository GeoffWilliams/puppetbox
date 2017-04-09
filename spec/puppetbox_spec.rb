require "spec_helper"

RSpec.describe Puppetbox do
  it "has a version number" do
    expect(Puppetbox::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
