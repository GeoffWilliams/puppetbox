require "puppetbox/result_set"
require "puppetbox/logger"
require "puppetbox/nodeset"
require "puppetbox/driver/vagrant"
require "puppetbox/report"
require "puppetbox/puppet"
require "puppetbox/util"

module PuppetBox
  class PuppetBox

    WORKING_DIR         = File.join(Dir.home, '.puppetbox')
    ACCEPTANCE_TEST_DIR = "spec/acceptance"
    ACCEPTANCE_DEFAULT  = "__ALL__"
    SETUP_SCRIPT_GLOB   = "setup.*"

    # we write testcases (smoketests) to this directory in our working dir...
    PUPPET_TESTCASE_TEMPDIR = "testcase"

    # ...and they appear on the system under test at this directory (like a
    # wormhole) - the driver class is responsible for making this happen
    PUPPET_TESTCASE_DIR   = "/testcase"

    def initialize(logger:nil, nodeset_file: nil, working_dir: nil, keep_test_system:false)
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
      @puppet_test_tempdir = File.join(@working_dir, PUPPET_TESTCASE_TEMPDIR)

      @keep_test_system = keep_test_system
    end


    # Enqueue a test into the `testsuite` for
    def enqueue_test_class(node_name, run_from, puppet_class, pre:nil)
      instantiate_driver(node_name, run_from)
      # eg @testsuite['centos']['apache']='include apache'
      test_name=puppet_class
      @testsuite[node_name]["tests"][test_name] = Puppet::include_class(puppet_class, pre:pre)
    end

    def run_testsuite
      @testsuite.each { |id, tests|
        # tests for each node
        run_puppet(tests["instance"], tests["tests"], logger:@logger, reset_after_run:true)
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
            keep_vm: @keep_test_system
          )

          # immediately validate the configuration to allow us to fail-fast
          di.validate_config
        else
          raise "PuppetBox only supports driver: 'vagrant' at the moment (requested: #{driver})"
        end

        @testsuite[node_name] = {
          "instance" => di,
          "tests"  => {},
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


    # Run puppet using `driver_instance` to execute `puppet_codes`
    # @param puppet_test Hash of test names <-> puppet code, eg {"apache"=>"include apache","nginx"=>"include nginx"}}
    def run_puppet(driver_instance, puppet_tests, logger:nil, reset_after_run:true)
      # use supplied logger in preference to the default puppetbox logger instance
      logger = logger || @logger
      logger.debug("#{driver_instance.node_name} running #{puppet_tests.size} tests")

      if driver_instance.open
        logger.debug("#{driver_instance.node_name} started")
        if driver_instance.self_test
          logger.debug("#{driver_instance.node_name} self_test OK, running puppet")
          puppet_tests.each { |test_name, puppet_code|
            if @result_set.class_size(driver_instance.node_name) > 0 and reset_after_run
              # purge and reboot the vm - this will save approximately 1 second
              # per class on the self-test which we now know will succeed
              driver_instance.reset
            end
            setup_test(driver_instance, test_name)
            logger.info("running test #{driver_instance.node_name} - #{test_name}")

            # write out the local test file
            relative_puppet_file = commit_testcase(
              puppet_tests, driver_instance.node_name, test_name
            )
            driver_instance.sync_testcase(driver_instance.node_name, test_name)

            puppet_file_remote = File.join(PUPPET_TESTCASE_DIR, relative_puppet_file)
            driver_instance.run_puppet_x2(puppet_file_remote)
            @logger.debug("Saved result #{driver_instance.node_name} #{test_name} #{driver_instance.result.passed?}")
            @result_set.save(driver_instance.node_name, test_name, driver_instance.result)

            Report::log_test_result_or_errors(
              @logger,
              driver_instance.node_name,
              test_name,
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

    #
    #@param testcases Pass in directly the testcases we are working against, to
    #   handle situations where `run_puppet()` was called directly
    def commit_testcase(testcases, node_name, test_name)
      puppet_code = testcases[test_name]
      relative_filename = Util.test_file_name(node_name, test_name)
      filename = File.join(@puppet_test_tempdir, relative_filename)
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, puppet_code)
      @logger.debug("Saved testcase #{filename}: #{puppet_code.slice(0,50)}...(ellipsed)")

      relative_filename
    end

  end
end
