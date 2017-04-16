require "spec_helper"
require "puppetbox/report"
require "puppetbox/result_set"
require "puppetbox/result"

RSpec.describe PuppetBox::Report do
  it "prints report without erroring" do
    rs = PuppetBox::ResultSet.new
    rs.save("node1", "class1", PuppetBox::Result.new)
    rs.save("node1", "class2", PuppetBox::Result.new)
    rs.save("node2", "class1", PuppetBox::Result.new)
    PuppetBox::Report::print(rs)
  end
end
