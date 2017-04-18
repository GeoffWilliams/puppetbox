require "spec_helper"
require "mock_driver_instance"
require "puppetbox/puppetbox"

RSpec.describe PuppetBox do
  it "has a version number" do
    expect(PuppetBox::VERSION).not_to be nil
  end


  it "runs puppet and returns passed with good mock driver_instance" do
    pb = PuppetBox::PuppetBox.new
    driver_instance = MockDriverInstance.new()
    driver_instance.pass
    pb.run_puppet(driver_instance, {'blah'=>'include blah'})
    expect(pb.result_set.passed?).to be true
  end

  it "runs puppet and returns failed with bad mock driver_instance" do
    pb = PuppetBox::PuppetBox.new
    driver_instance = MockDriverInstance.new()
    driver_instance.fail
    pb.run_puppet(driver_instance, {'blah'=>'include blah'})
    expect(pb.result_set.passed?).to be false
  end


  it "enqueues a test" do
    pb = PuppetBox::PuppetBox.new(nodeset_file: NODESET_GOOD)
    pb.enqueue_test_class(NODE_GOOD, "/tmp", "test_class")

    # pass if reached without error
  end

  it "rejects enqueuing a test when there is no correspondng node definition" do
    pb = PuppetBox::PuppetBox.new
    expect{pb.enqueue_test_class("nothere", "/tmp", "test_class")}.to raise_error /is not defined/
  end

  it "rejects enqueuing a test when node definition does not specify box" do
    pb = PuppetBox::PuppetBox.new(nodeset_file: NODESET_MISSING_BOX)
    expect{pb.enqueue_test_class(NODE_MISSING_BOX, "/tmp", "test_class")}.to raise_error /must specify box/
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

  it "records results (check by count)" do
    pb = PuppetBox::PuppetBox.new

    driver_instance = MockDriverInstance.new()
    driver_instance.fail

    expect(pb.result_set.test_size).to be 0
    pb.run_puppet(driver_instance, {'inky'=>'include inky'})
    expect(pb.result_set.test_size).to be 1
    pb.run_puppet(driver_instance, {'blinky'=>'include blinky'})
    expect(pb.result_set.test_size).to be 2

  end
end
