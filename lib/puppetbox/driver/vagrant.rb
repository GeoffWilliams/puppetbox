require 'vagrantomatic/vagrantomatic'
require 'puppetbox/result'
require 'fileutils'
require "puppetbox/logger"

module PuppetBox
  module Driver
    class Vagrant
      WORKING_DIR_VAGRANT   = "vagrant"
      PUPPET_CODE_MOUNT     = "/etc/puppetlabs/code/environments/production"

      # mount spec/ into the same directory name inside the VM for simplicity -
      # now we can easility access fixtures, tests, etc
      SPEC_ACCEPTANCE_MOUNT = "spec:/spec"

      PUPPET_TESTCASE_DIR   = "/testcase"

      def node_name
        @name
      end

      def initialize(name, codedir, config, keep_vm:false, working_dir:nil, logger: nil)

        @name           = name
        @keep_vm        = keep_vm
        @working_dir    = working_dir || PuppetBox::WORKING_DIR
        @vagrant_vm_dir = File.join(@working_dir, WORKING_DIR_VAGRANT)
        @testcase_dir   = File.join(@working_dir, PUPPET_TESTCASE_DIR)
        @config         = config
        @result         = Result.new
        @logger         = Logger.new(logger).logger

        # setup the instance
        @vom = Vagrantomatic::Vagrantomatic.new(vagrant_vm_dir:@vagrant_vm_dir, logger:@logger)
        @logger.debug("creating instance metadata for #{@name}")
        @vm = @vom.instance(@name, config:@config)

        # the code under test
        @vm.add_shared_folder("#{codedir}:#{PUPPET_CODE_MOUNT}")

        # ./spec/acceptance directory
        @vm.add_shared_folder(SPEC_ACCEPTANCE_MOUNT)

        # mount the temporary testcase files (smoketests - the generated files
        # holding 'include apache', etc)
        @vm.add_shared_folder("#{@testcase_dir}:#{PUPPET_TESTCASE_DIR}")

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
      def run_puppet(puppet_file)
        status_code, messages = @vm.run(
          "sudo -i puppet apply --detailed-exitcodes #{puppet_file}"
        )
        @result.save(status_code, messages)
        @result.passed?
      end

      # Open a connection to a box (eg start a vm, ssh to a host etc)
      def open()
        # make sure working dir exists...
        FileUtils.mkdir_p(@working_dir)
        FileUtils.mkdir_p(@vagrant_vm_dir)
        FileUtils.mkdir_p(@testcase_dir)
        @vm.save

        @logger.debug("Instance saved and ready for starting")
        started = @vm.start
      end

      # Close a connection to a box (eg stop a vm, probaly doesn't need to do
      # anything on SSH...)
      def close()
        if @keep_vm
          vagrant_cmd = "cd #{@vm.vm_instance_dir} && vagrant ssh"
          @logger.info("VM #{@name} left running on user request, `#{vagrant_cmd}` to access - be sure to clean up your VMs!")
        else
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

      # Run a script on the VM by name.  We pass in the script name and are able
      # to run because the ./spec/acceptance directory is mounted inside the VM
      #
      # We can figure out windows/linux scripts based on the filename too
      def run_setup_script(script_file)

        if script_file =~ /.ps1$/
          # powershell - not supported yet
          raise("Windows not supported yet https://github.com/GeoffWilliams/puppetbox/issues/3")
        else
          # force absolute path
          script_file = "/#{script_file}"

          @logger.info("Running setup script #{script_file} on #{@name}")
          status_code, messages = @vm.run("sudo -i #{script_file}")
          status = (status_code == 0)
          if status
            @logger.info("setup script #{script_file} executed successfully")
          else
            # our tests are fubar if any setup script failed
            message = messages.join("\n")
            raise("setup script #{script_file} failed on #{node_name}:  #{message}")
          end
        end
        status
      end

      def run_puppet_x2(puppet_file)
        # if you need to link a module into puppet's modulepath either do it
        # before running puppet (yet to be supported) or use the @config hash
        # for vagrant to mount what you need as a shared folder
        if run_puppet(puppet_file)
          # Only do the second run if the first run passes
          run_puppet(puppet_file)
        end
      end

      # noop
      def sync_testcase(node_name, test_name)
      end

    end
  end

end
