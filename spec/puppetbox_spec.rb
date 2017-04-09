require "spec_helper"
require "mock_driver_instance"

RSpec.describe PuppetBox do
  it "has a version number" do
    expect(PuppetBox::VERSION).not_to be nil
  end


  it "runs puppet and returns passed with good mock driver_instance" do
    driver_instance = MockDriverInstance.new()
    driver_instance.pass
    expect(driver_instance.result.passed).to be true
  end

  it "runs puppet and returns failed with bad mock driver_instance" do
    driver_instance = MockDriverInstance.new()
    driver_instance.fail
    expect(driver_instance.result.passed).to be false
  end

end
