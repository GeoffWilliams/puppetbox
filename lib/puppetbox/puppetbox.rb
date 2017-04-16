require "puppetbox/result_set"
require "puppetbox/logger"
require "puppetbox/nodeset"
require "puppetbox/driver/vagrant"
require "puppetbox/report"

module PuppetBox
  class PuppetBox

    WORKING_DIR         = File.join(Dir.home, '.puppetbox')
    ACCEPTANCE_TEST_DIR = "spec/acceptance"
    ACCEPTANCE_DEFAULT  = "__ALL__"
    SETUP_SCRIPT_GLOB   = "setup.*"

    def initialize(logger:nil, nodeset_file: nil, working_dir: nil)
      # The results of all tests on all driver instances
      @result_set = ResultSet.new

      # A complete test suite of tests to run - includes driver instance, host
      # and classes
      @testsuite = {}
      @logger = Logger.new(logger).logger

      # the nodesets file contains a YAML representation of a hash containing
      # the node name, config options, driver to use etc - so external tools can
      # talk to use about nodes of particular name and puppetbox will sort out
      # the how and why of what this exactly should involve
      @nodeset = NodeSet.new(nodeset_file)

      @working_dir = working_dir || WORKING_DIR
    end


    # Enqueue a test into the `testsuite` for
    def enqueue_test(node_name, run_from, puppet_class)
      instantiate_driver(node_name, run_from)
      @testsuite[node_name]["classes"] << puppet_class

    end

    def run_testsuite
      @testsuite.each { |id, tests|
        run_puppet(tests["instance"], tests["classes"], logger:@logger, reset_after_run:true)
      }
    end

    def instantiate_driver(node_name, run_from)
      node    = @nodeset.get_node(node_name)
      config  = node["config"]
      driver  = node["driver"]
      if @testsuite.has_key?(node_name)
        @logger.debug("#{node_name} already registered")
      else
        @logger.debug("Creating new driver instance for #{node_name}")

        # for now just support the vagrant driver
        case driver
        when "vagrant"

          # For the moment, just use the checked out production environment inside
          # onceover's working directory.  The full path resolves to something like
          # .onceover/etc/puppetlabs/code/environments/production -- in the
          # directory your running onceover from
          #
          # we pass in our pre-configured logger instance for separation and to
          # reduce the amount of log output.  We only print puppet apply output for
          # failed runs, however, if user runs in onceover's --debug mode, then we
          # will print the customary ton of messages, including those from vagrant
          # itself.
          puts config["box"]
          di = Driver::Vagrant.new(
            node_name,
            run_from,
            config,
            # "#{repo.tempdir}/etc/puppetlabs/code/environments/production",
            logger: @logger,
            working_dir: @working_dir,
          )

          # immediately validate the configuration to allow us to fail-fast
          di.validate_config
        else
          raise "PuppetBox only supports driver: 'vagrant' at the moment (requested: #{driver})"
        end

        @testsuite[node_name] = {
          "instance" => di,
          "classes"  => [],
        }
      end
    end

    # Print a summary of *all* results to STDOUT.  Does not include the error(s)
    # if any - these would have been printed after each individual test ran
    def print_results
      Report::print(@result_set)
    end

    def result_set
      @result_set
    end

    def passed?
      @result_set.passed?
    end

    # Sometimes you need to run a script before running a class, or just on
    # particular host(s).  Check for the presence of a bash or powershell script
    # and execute it on the system under test.  If there is an error fail all
    # tests immediately since it means our test setup is invalid.
    #
    # Naming convention/example:
    # └── SLES-12.1-64
    #    ├── __ALL__
    #    │   └── setup.sh
    #    └── role__puppet__master
    #        └── setup.sh
    #
    def setup_test(driver_instance, puppet_class)
      script_filename_base = File.join(ACCEPTANCE_TEST_DIR, driver_instance.node_name)

      # 1st choice - exact match on classname (with :: converted to __)
      script_filename_class = File.join(
        script_filename_base,
        puppet_class.gsub(/::/,'__'),
        SETUP_SCRIPT_GLOB
      )
      found = Dir.glob(script_filename_class)
      if found.any?
        script_target = found[0]
      else
        # 2nd choice - the __ALL__ directory
        script_filename_default = File.join(
          script_filename_base,
          ACCEPTANCE_DEFAULT,
          SETUP_SCRIPT_GLOB
        )
        found = Dir.glob(script_filename_default)
        if found.any?
          @logger.info(
            "Using setup script from #{script_filename_default} on "\
            "#{driver_instance.node_name} for #{puppet_class}, create "\
            "#{script_filename_class} to override")
          script_target = found[0]
        else
          script_target = false
          @logger.info(
            "No setup scripts found for #{driver_instance.node_name} and "\
            "#{puppet_class} create #{script_filename_default} or "\
            "#{script_filename_class} if required")
        end
      end
      if script_target
        driver_instance.run_setup_script(script_target)
      end
    end

    # Run puppet using `driver_instance` to execute
    def run_puppet(driver_instance, puppet_classes, logger:nil, reset_after_run:true)
      # use supplied logger in preference to the default puppetbox logger instance
      logger = logger || @logger
      logger.debug("#{driver_instance.node_name} running test for #{puppet_classes}")
      puppet_classes = Array(puppet_classes)

      if driver_instance.open
        logger.debug("#{driver_instance.node_name} started")
        if driver_instance.self_test
          logger.debug("#{driver_instance.node_name} self_test OK, running puppet")
          puppet_classes.each { |puppet_class|
            if @result_set.class_size(driver_instance.node_name) > 0 and reset_after_run
              # purge and reboot the vm - this will save approximately 1 second
              # per class on the self-test which we now know will succeed
              driver_instance.reset
            end
            setup_test(driver_instance, puppet_class)
            logger.info("running test #{driver_instance.node_name} - #{puppet_class}")
            driver_instance.run_puppet_x2(puppet_class)
            @result_set.save(driver_instance.node_name, puppet_class, driver_instance.result)

            Report::log_test_result_or_errors(
              @logger,
              driver_instance.node_name,
              puppet_class,
              driver_instance.result,
            )
          }
          logger.debug("#{driver_instance.node_name} test completed, closing instance")
        else
          raise "#{driver_instance.node_name} self test failed, unable to continue"
        end
      else
        raise "#{driver_instance.node_name} failed to start, unable to continue"
      end

      driver_instance.close
    end

  end
end
