require "spec_helper"
require "puppetbox/result_set"
require "puppetbox/result"

RSpec.describe PuppetBox::ResultSet do

  it "saves results correctly" do
    rs = PuppetBox::ResultSet.new
    rs.save("foo_node", "bar_class", PuppetBox::Result.new)
    expect(rs.node_size).to be 1
    expect(rs.class_size("foo_node")).to be 1
    expect(rs.test_size).to be 1
  end

  it "rejects saves where a Result object is not passed" do
    rs = PuppetBox::ResultSet.new

    expect{rs.save("foo_node", "bar_class", "should not be accepted")}.to raise_error /PuppetBox::Result/
  end

  it "accepts multiple results for the same node" do
    rs = PuppetBox::ResultSet.new
    rs.save("foo_node", "bar_class", PuppetBox::Result.new)
    rs.save("foo_node", "baz_class", PuppetBox::Result.new)
    expect(rs.node_size).to be 1
    expect(rs.class_size("foo_node")).to be 2
    expect(rs.test_size).to be 2
  end

  it "rejects multiple results from the same class" do
    rs = PuppetBox::ResultSet.new
    rs.save("foo_node", "bar_class", PuppetBox::Result.new)
    expect{rs.save("foo_node", "bar_class", PuppetBox::Result.new)}.to raise_error /Duplicate results for class/i
  end

  it "reports overall fail status when no tests were executed" do
    rs = PuppetBox::ResultSet.new
    rs.save("foo_node", "bar_class", PuppetBox::Result.new)
    expect(rs.passed?).to be false
  end

  it "reports overall pass status when tests pass" do
    rs = PuppetBox::ResultSet.new
    res = PuppetBox::Result.new
    res.save(0, "fake passing test")
    res.save(0, "fake passing test")
    rs.save("foo_node", "bar_class", res)
    expect(rs.passed?).to be true
  end

  it "reports overall fail status when tests fail" do
    rs = PuppetBox::ResultSet.new
    res = PuppetBox::Result.new
    res.save(255, "fake erroring test")
    res.save(0, "fake passing test")
    # final check on result set to eliminate errors in the passed? logic.  This
    # has already been tested elsewhere but leaving this since it makes it proves
    # whether this testcase experienced error in Result or ResultSet
    expect(res.passed?).to be false
    rs.save("foo_node", "bar_class", res)
    expect(rs.passed?).to be false
  end

  it "reports overall fail status when resultset empty" do
    rs = PuppetBox::ResultSet.new
    expect(rs.passed?).to be false
  end

  it "returns zero when result count for non-existant node are requested" do
    rs = PuppetBox::ResultSet.new
    expect(rs.class_size("nonexistant")).to be 0
  end

  it "gives zero when test count for empty instance requested" do
    rs = PuppetBox::ResultSet.new
    expect(rs.test_size).to be 0
  end
  # it "saves results correctly" do
  #   rs = PuppetBox::ResultSet.new
  #   rs.save("foo_node", "bar_class", "should never be accepted")
  #   expect{PuppetBox::NodeSet.parse(NODESET_INVALID_VERSION)}.to raise_error /version/i
  # end

  # def save(key, result)
  #   @results[key] = result
  # end
  #
  # def passed?
  #   @results.map { |key,result|
  #     result.passed?
  #   }.all?
  # end
  #
  # def data
  #   @results
  # end
  #
  # def size
  #   @results.size
  # end

end
