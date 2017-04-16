require 'vagrantomatic/vagrantomatic'
require 'puppetbox/result'
require 'fileutils'
require "puppetbox/logger"

module PuppetBox
  module Driver
    class Vagrant
      WORKING_DIR_VAGRANT   = "vagrant"
      PUPPET_CODE_MOUNT     = "/etc/puppetlabs/code/environments/production"
      SPEC_ACCEPTANCE_MOUNT = "spec/acceptance:/acceptance"

      def node_name
        @name
      end

      def initialize(name, codedir, config, keep_vm:false, working_dir:nil, logger: nil)

        @name         = name
        @keep_vm      = keep_vm
        @working_dir  = File.join((working_dir || PuppetBox::WORKING_DIR), WORKING_DIR_VAGRANT)
        @config       = config
        @result       = Result.new
        @logger       = Logger.new(logger).logger

        # setup the instance
        @vom = Vagrantomatic::Vagrantomatic.new(vagrant_vm_dir:@working_dir, logger:@logger)
        @logger.debug("creating instance metadata for #{@name}")
        @vm = @vom.instance(@name, config:@config)

        # the code under test
        @vm.add_shared_folder("#{codedir}:#{PUPPET_CODE_MOUNT}")

        # ./spec/acceptance directory
        @vm.add_shared_folder(SPEC_ACCEPTANCE_MOUNT)

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
        @result.save(status_code, messages)
        @result.passed?
      end

      # Open a connection to a box (eg start a vm, ssh to a host etc)
      def open()
        # make sure working dir exists...
        FileUtils.mkdir_p(@working_dir)
        @vm.save

        @logger.debug("Instance saved and ready for starting")
        started = @vm.start
      end

      # Close a connection to a box (eg stop a vm, probaly doesn't need to do
      # anything on SSH...)
      def close()
        if ! @keep_vm
          @logger.info("Closing #{@name}")
          @vm.purge
        end
      end

      def reset()
        @vm.reset
      end

      def validate_config
        @vm.validate_config
      end

      # Test that a VM is operational and able to run puppet
      def self_test()
        status_code, messages = @vm.run("sudo -i puppet --version")
        self_test = (status_code == 0)
        if self_test
          @logger.info("Running under Puppet version: #{messages[0].strip}")
        else
          @logger.error("Error #{status_code} running puppet: #{messages}")
        end
        self_test
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
