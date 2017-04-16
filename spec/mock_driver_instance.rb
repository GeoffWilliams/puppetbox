require "puppetbox/result"

class MockDriverInstance

  def initialize
    @result = PuppetBox::Result.new()
  end

  def node_name
    "mock_node"
  end

  def pass
    @result.save(PuppetBox::Result::PS_OK, "fake passed report")
    @result.save(PuppetBox::Result::PS_OK, "fake passed report")
  end

  def fail
    @result.save(PuppetBox::Result::PS_OK, "fake passed report")
    @result.save(PuppetBox::Result::PS_NOT_IDEMPOTENT, "fake not idempotent report")
  end

  def run_puppet_x2(puppet_class)
  end

  def result
    @result
  end

  def open
    true
  end

  def self_test
    true
  end

  def close
    true
  end

  def reset
  end

end
