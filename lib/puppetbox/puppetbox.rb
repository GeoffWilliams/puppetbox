require "puppetbox/result_set"
require "puppetbox/logger"
require "puppetbox/nodeset"
require "puppetbox/driver/vagrant"
require "puppetbox/report"

module PuppetBox
  class PuppetBox

    WORKING_DIR = File.join(Dir.home, '.puppetbox')

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

      # di
      # result = ::PuppetBox.run_puppet(di, puppet_class)

      # indent = "  "
      # if result.passed
      #   logger.info("#{indent}#{host}:#{puppet_class} --> PASSED")
      # else
      #   logger.error("#{indent}#{host}:#{puppet_class} --> FAILED")
      #   # since we stop running on failure, the error messages will be in the
      #   # last element of the result.messages array (tada!)
      #   messages = result.messages
      #   messages[-1].each { |line|
      #     # puts "XXXXXXX #{line}"
      #     logger.error "#{indent}#{host} - #{line}"
      #   }
      #   #   puts "size of result messages #{result.messages.size}"
      #   #   puts "size of result messages #{result.messages[0].size}"
      #   #   run.each { |message_arr|
      #   #     puts message_arr
      #   #     #message_arr.each { |line|
      #   #   #    puts line
      #   #   #  }
      #   #     # require 'pry'
      #   #     # binding.pry
      #   #     #puts "messages size"
      #   #     #puts messages.size
      #   #   #  messages.each { |message|
      #   #       # messages from the puppet run are avaiable in a nested array of run
      #   #       # and then lines so lets print each one out indended from the host so
      #   #       # we can see what's what
      #   #   #    logger.error("#{host}       #{message}")
      #   #   #  }
      #   #   }
      #   # }
      # end
      # result.passed
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
