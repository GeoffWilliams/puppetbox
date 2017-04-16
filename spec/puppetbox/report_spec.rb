require "spec_helper"
require "puppetbox/report"
require "puppetbox/result_set"
require "puppetbox/result"
require "puppetbox/logger"

RSpec.describe PuppetBox::Report do
  it "prints report without erroring" do
    rs = PuppetBox::ResultSet.new
    rs.save("node1", "class1", PuppetBox::Result.new)
    rs.save("node1", "class2", PuppetBox::Result.new)
    rs.save("node2", "class1", PuppetBox::Result.new)
    PuppetBox::Report::print(rs)
  end

  it "prints individual test status without erroring" do
    PuppetBox::Report::log_test_result_or_errors(
      PuppetBox::Logger.new.logger,
      "foo",
      "bar",
      PuppetBox::Result.new
    )
  end
end
