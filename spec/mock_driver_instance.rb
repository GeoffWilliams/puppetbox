require "puppetbox/result"

class MockDriverInstance
  def initialize
  end

  def pass
    @result = PuppetBox::Result.new()
    @result.report(PuppetBox::Result::PS_OK, "fake passed report")
    @result.report(PuppetBox::Result::PS_OK, "fake passed report")
  end

  def fail
    @result = PuppetBox::Result.new()
    @result.report(PuppetBox::Result::PS_OK, "fake passed report")
    @result.report(PuppetBox::Result::PS_NOT_IDEMPOTENT, "fake not idempotent report")
  end

  def run_puppet_x2
  end

  def result
    @result
  end

  def open
    true
  end

  def self_test
  end

  def close
    true
  end


end
