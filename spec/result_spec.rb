require "spec_helper"
require "puppetbox/result"

RSpec.describe PuppetBox::Result do
  it "reports status ok as passed" do
    res = PuppetBox::Result.new()
    res.report(2,['blah'])
    res.report(0,['blah'])
    expect(res.passed?).to be true
  end

  it "reports status not idempotent as failed" do
    res = PuppetBox::Result.new()
    res.report(2,['blah'])
    res.report(2,['blah'])
    expect(res.passed?).to be false
  end

  it "reports status error as failed" do
    res = PuppetBox::Result.new()
    res.report(4,['blah'])
    res.report(0,['blah'])
    expect(res.passed?).to be false
  end

  it "reports status unkown as failed" do
    res = PuppetBox::Result.new()
    res.report(240,['blah'])
    expect(res.passed?).to be false
  end

  it "returns all messages from all runs correctly" do
    res = PuppetBox::Result.new()
    res.report(PuppetBox::Result::PS_OK,['first'])
    res.report(PuppetBox::Result::PS_OK,['second'])

    messages = res.messages
    expect(messages[0]).to eq ['first']
    expect(messages[1]).to eq ['second']
  end

  it "returns messages from first run only correctly" do
    res = PuppetBox::Result.new()
    res.report(0,['first'])
    res.report(0,['second'])

    messages = res.messages(0)
    expect(messages.size).to be 1
    expect(messages[0]).to eq ['first']
  end

  it "returns messages from second run only correctly" do
    res = PuppetBox::Result.new()
    res.report(0,['first'])
    res.report(0,['second'])

    messages = res.messages(1)
    expect(messages[0]).to eq ['second']
  end

  it "raises when accessing non-existant report" do
    res = PuppetBox::Result.new()
    res.report(0,['first'])
    res.report(0,['second'])

    expect{res.messages(2)}.to raise_error /does not exist/
  end

  it "does not report tests passed when no tests executed" do
    res = PuppetBox::Result.new()

    # we return nil in this special case (which will test as ==false)
    expect(res.passed?).to be nil
  end
end
