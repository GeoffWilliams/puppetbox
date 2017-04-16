require "spec_helper"
require 'puppetbox/puppetbox'
require 'puppetbox/driver/vagrant'

RSpec.describe PuppetBox do
  CODE_FIXTURE            = File.join(File.dirname(File.expand_path(__FILE__)), "../spec/fixtures/production")
  CONFIG_GOOD             = {'box' => 'puppetlabs/centos-7.2-64-puppet'}
  CONFIG_NON_EXISTENT_BOX = {'box' => 'no/suchbox'}
  CONFIG_MISSING_BOX      = {}
  CONFIG_BAD_SELF_TEST    = {'box' => 'puppetlabs/centos-7.2-64-nocm'}

  # Cannot run vagrant in travis ;-)
  # https://github.com/travis-ci/travis-ci/issues/6060
  #
  # ...damn!  That means we must detect CI system and not run tests there.  It's
  # therefore vital that `bundle exec rake spec` is run manually for each commit
  if ENV['CI'] != 'true'
    it "reports passing code correctly" do
      di  = PuppetBox::Driver::Vagrant.new('test',CODE_FIXTURE, CONFIG_GOOD)
      pb  = PuppetBox::PuppetBox.new
      res = pb.run_puppet(di, "passing")
      expect(pb.result_set.passed?).to be true
    end

    it "reports failing code correctly" do
      di  = PuppetBox::Driver::Vagrant.new('test',CODE_FIXTURE, CONFIG_GOOD)
      pb  = PuppetBox::PuppetBox.new
      pb.run_puppet(di, "failing")
      expect(pb.result_set.passed?).to be false
    end

    it "reports error starting vagrant with non-existent box" do
      # will fail due to missing box
      di  = PuppetBox::Driver::Vagrant.new('bad_box', CODE_FIXTURE, CONFIG_NON_EXISTENT_BOX)
      pb  = PuppetBox::PuppetBox.new(nodeset_file: NODESET_MISSING_BOX)
      expect{pb.run_puppet(di, "passing")}.to raise_error /failed to start/
    end


    it "reports error starting vagrant with self-test failure" do
      # will fail due to missing puppet installation
      di  = PuppetBox::Driver::Vagrant.new('bad_self_test', CODE_FIXTURE ,CONFIG_BAD_SELF_TEST)
      pb  = PuppetBox::PuppetBox.new()
      expect{pb.run_puppet(di, "passing")}.to raise_error /self test failed/
    end

    it "enqueue and run tests works" do
      pb  = PuppetBox::PuppetBox.new(nodeset_file: NODESET_GOOD)
      pb.enqueue_test(NODE_GOOD, CODE_FIXTURE, "passing")
      pb.run_testsuite

      # pass
    end

    it "enqueue and run multiple tests works" do
      pb  = PuppetBox::PuppetBox.new(nodeset_file: NODESET_GOOD)
      pb.enqueue_test(NODE_GOOD, CODE_FIXTURE, "passing")
      pb.enqueue_test(NODE_GOOD, CODE_FIXTURE, "passing::class2")
      pb.run_testsuite

      # pass
    end
  end
end
