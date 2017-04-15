require "spec_helper"
require "mock_driver_instance"
require "puppetbox/puppetbox"

RSpec.describe PuppetBox do
  it "has a version number" do
    expect(PuppetBox::VERSION).not_to be nil
  end


  it "runs puppet and returns passed with good mock driver_instance" do
    driver_instance = MockDriverInstance.new()
    driver_instance.pass
    expect(driver_instance.result.passed?).to be true
  end

  it "runs puppet and returns failed with bad mock driver_instance" do
    driver_instance = MockDriverInstance.new()
    driver_instance.fail
    expect(driver_instance.result.passed?).to be false
  end

  it "runs puppet and returns passed with good mock driver_instance" do
    driver_instance = MockDriverInstance.new()
    driver_instance.pass
    expect(driver_instance.result.passed?).to be true
  end

  it "runs puppet and returns failed with bad mock driver_instance" do
    driver_instance = MockDriverInstance.new()
    driver_instance.fail
    expect(driver_instance.result.passed?).to be false
  end

  it "enqueues a test" do
    pb = PuppetBox::PuppetBox.new(nodeset_file: NODESET_GOOD)
    pb.enqueue_test(NODE_GOOD, "/tmp", "test_class")

    # pass if reached without error
  end

  it "rejects enqueuing a test when there is no correspondng node definition" do
    pb = PuppetBox::PuppetBox.new
    expect{pb.enqueue_test("nothere", "/tmp", "test_class")}.to raise_error /is not defined/
  end

  it "rejects enqueuing a test when node definition does not specify box" do
    pb = PuppetBox::PuppetBox.new(nodeset_file: NODESET_MISSING_BOX)
    expect{pb.enqueue_test(NODE_MISSING_BOX, "/tmp", "test_class")}.to raise_error /must specify box/
  end

  it "instantiates a driver for named test node correctly" do
    pb = PuppetBox::PuppetBox.new(nodeset_file: NODESET_GOOD)
    pb.instantiate_driver(NODE_GOOD, "/tmp")

    # pass if reached without error
  end

  it "instantiates a driver for named test node correctly multiple times" do
    pb = PuppetBox::PuppetBox.new
    pb.instantiate_driver(NODE_GOOD, "/tmp")
    pb.instantiate_driver(NODE_GOOD, "/tmp")

    # pass if reached without error
  end

end
