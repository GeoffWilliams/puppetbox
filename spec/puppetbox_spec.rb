require "spec_helper"
require "mock_driver_instance"
require "puppetbox/puppetbox"

RSpec.describe PuppetBox do
  it "has a version number" do
    expect(PuppetBox::VERSION).not_to be nil
  end

end
