require "spec_helper"
require "puppetbox/result"

RSpec.describe PuppetBox::Result do
  it "reports status ok as passed" do
    res = PuppetBox::Result.new(PuppetBox::Result::PS_OK,'blah')
    expect(res.passed).to be true
  end

  it "reports status not idempotent as failed" do
    res = PuppetBox::Result.new(PuppetBox::Result::PS_NOT_IDEMPOTENT,'blah')
    expect(res.passed).to be false
  end

  it "reports status error as failed" do
    res = PuppetBox::Result.new(PuppetBox::Result::PS_ERROR,'blah')
    expect(res.passed).to be false
  end

  it "reports status unkown as failed" do
    res = PuppetBox::Result.new(-1,'blah')
    expect(res.passed).to be false
  end
end
