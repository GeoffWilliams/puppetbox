require 'vagrantomatic/vagrantomatic'
require 'puppetbox/result'
require 'fileutils'
require "puppetbox/logger"

module PuppetBox
  module Driver
    class Vagrant
      # fixme - seems abandoned, might need to make my own :(
      DEFAULT_VAGRANT_BOX = "puppetlabs/centos-7.2-64-puppet"
      PUPPET_CODE_MOUNT   = "/etc/puppetlabs/code/environments/production"

      def initialize(name, codedir, keep_vm:true, working_dir:nil, config:{'box'=> DEFAULT_VAGRANT_BOX}, logger: nil)
        @name         = name
        @keep_vm      = keep_vm
        @working_dir  = working_dir || File.join(Dir.home, '.puppetbox')
        @config       = config
        @result       = PuppetBox::Result.new
        @logger       = PuppetBox::Logger.new(logger).logger

        # Add the code dir to the config has so that it will automatically become
        # a shared folder when the VM boots
        @config["folders"] = "#{codedir}:#{PUPPET_CODE_MOUNT}"
        @logger.debug "instance #{name} initialised"
      end

      def result
        @result
      end

      # convert a derelelict (vagrant library used by vagrantomatic) exectutor to
      # a result object as used by puppetbox
      #
      # Puppet exit status codes:
      #   0: The run succeeded with no changes or failures; the system was already in the desired state.
      #   1: The run failed, or wasn't attempted due to another run already in progress.
      #   2: The run succeeded, and some resources were changed.
      #   4: The run succeeded, and some resources failed.
      #   6: The run succeeded, and included both changes and failures.
      def run_puppet(puppet_class)
        status_code, messages = @vm.run(
          "sudo -i puppet apply --detailed-exitcodes -e 'include #{puppet_class}'"
        )
        @result.report(status_code, messages)
        @result.passed
      end

      # Open a connection to a box (eg start a vm, ssh to a host etc)
      def open()
        # make sure working dir exists...
        FileUtils.mkdir_p(@working_dir)
        vom = Vagrantomatic::Vagrantomatic.new(vagrant_vm_dir: @working_dir, logger: @logger)

        @logger.debug("reading instance metadata for #{@name}")
        @vm = vom.instance(@name)

        @logger.debug("...setting instance config and saving")

        @vm.config=(@config)
        @vm.save
        @logger.debug("Instance saved and ready for starting")
        @vm.start
      end

      # Close a connection to a box (eg stop a vm, probaly doesn't need to do
      # anything on SSH...)
      def close()
        if ! @keep_vm
          @vm.purge
        end
      end

      # Test that a VM is operational and able to run puppet
      def self_test()
        status_code, messages = @vm.run("sudo -i puppet --version")
        status_code == 0
      end

      def run_puppet_x2(puppet_class)
        # if you need to link a module into puppet's modulepath either do it
        # before running puppet (yet to be supported) or use the @config hash
        # for vagrant to mount what you need as a shared folder
        if run_puppet(puppet_class)
          # Only do the second run if the first run passes
          run_puppet(puppet_class)
        end
      end

    end
  end

end
