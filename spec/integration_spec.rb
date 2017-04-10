require "spec_helper"
require 'puppetbox/driver/vagrant'

RSpec.describe PuppetBox do
  CODE_FIXTURE = File.join(File.dirname(File.expand_path(__FILE__)), "../spec/fixtures/production")

  it "reports passing code correctly" do
    di = PuppetBox::Driver::Vagrant.new('test',CODE_FIXTURE)
    res = PuppetBox.run_puppet(di, "passing")
    expect(res.passed).to be true
  end

  it "reports failing code correctly" do
    di = PuppetBox::Driver::Vagrant.new('test',CODE_FIXTURE)
    res = PuppetBox.run_puppet(di, "failing")
    expect(res.passed).to be false
  end

end
