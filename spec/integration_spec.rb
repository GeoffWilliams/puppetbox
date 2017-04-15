require "spec_helper"
require 'puppetbox/puppetbox'
require 'puppetbox/driver/vagrant'

RSpec.describe PuppetBox do
  CODE_FIXTURE = File.join(File.dirname(File.expand_path(__FILE__)), "../spec/fixtures/production")

  # Cannot run vagrant in travis ;-)
  # https://github.com/travis-ci/travis-ci/issues/6060
  #
  # ...damn!  That means we must detect CI system and not run tests there.  It's
  # therefore vital that `bundle exec rake spec` is run manually for each commit
  if ENV['CI'] != 'true'
    it "reports passing code correctly" do
      di = PuppetBox::Driver::Vagrant.new('test',CODE_FIXTURE)
      pb = PuppetBox::PuppetBox.new
      res = pb.run_puppet(di, "passing")
      expect(res.passed?).to be true
    end

    it "reports failing code correctly" do
      di = PuppetBox::Driver::Vagrant.new('test',CODE_FIXTURE)
      pb = PuppetBox::PuppetBox.new
      res = pb.run_puppet(di, "failing")
      expect(res.passed?).to be false
    end

  end
end
