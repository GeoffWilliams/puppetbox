require "spec_helper"
require "puppetbox/result"

RSpec.describe PuppetBox::Result do
  it "reports status ok as passed" do
    res = PuppetBox::Result.new()
    res.report(PuppetBox::Result::PS_OK,'blah')
    res.report(PuppetBox::Result::PS_OK,'blah')
    expect(res.passed).to be true
  end

  it "reports status not idempotent as failed" do
    res = PuppetBox::Result.new()
    res.report(PuppetBox::Result::PS_OK,'blah')
    res.report(PuppetBox::Result::PS_NOT_IDEMPOTENT,'blah')
    expect(res.passed).to be false
  end

  it "reports status error as failed" do
    res = PuppetBox::Result.new()
    res.report(PuppetBox::Result::PS_ERROR,'blah')
    res.report(PuppetBox::Result::PS_OK,'blah')
    expect(res.passed).to be false
  end

  it "reports status unkown as failed" do
    res = PuppetBox::Result.new()
    res.report(-1,'blah')
    expect(res.passed).to be false
  end

  it "returns all messages from all runs correctly" do
    res = PuppetBox::Result.new()
    res.report(PuppetBox::Result::PS_OK,'first')
    res.report(PuppetBox::Result::PS_OK,'second')

    messages = res.messages
    expect(messages[0]).to eq 'first'
    expect(messages[1]).to eq 'second'
  end

  it "returns messages from first run only correctly" do
    res = PuppetBox::Result.new()
    res.report(PuppetBox::Result::PS_OK,'first')
    res.report(PuppetBox::Result::PS_OK,'second')

    messages = res.messages(0)
    expect(messages.size).to be 1
    expect(messages[0]).to eq 'first'
  end

  it "returns messages from second run only correctly" do
    res = PuppetBox::Result.new()
    res.report(PuppetBox::Result::PS_OK,'first')
    res.report(PuppetBox::Result::PS_OK,'second')

    messages = res.messages(1)
    expect(messages[0]).to eq 'second'
  end

  it "raises when accessing non-existant report" do
    res = PuppetBox::Result.new()
    res.report(PuppetBox::Result::PS_OK,'first')
    res.report(PuppetBox::Result::PS_OK,'second')

    expect{res.messages(2)}.to raise_error /does not exist/
  end
end
