require "puppetbox/result_set"
require "puppetbox/logger"
require "puppetbox/nodeset"

module PuppetBox
  class PuppetBox

    def initialize(logger:nil, nodeset_file: nil)
      # The results of all tests on all driver instances
      @result_set = ResultSet.new

      # A complete test suite of tests to run - includes driver instance, host
      # and classes
      @testsuite = {}
      @logger = Logger.new(logger)

      # the nodesets file contains a YAML representation of a hash containing
      # the node name, config options, driver to use etc - so external tools can
      # talk to use about nodes of particular name and puppetbox will sort out
      # the how and why of what this exactly should involve
      @nodesets = NodeSet.parse(nodeset_file)
    end


    # Enqueue a test into the `testsuite` for
    def enqueue_test(node_name, run_from, puppet_class)
      enqueue_driver_instance(node_name, run_from)
      @testsuite[node_name]["classes"] << puppet_class
      #  get_driver_instance(driver_name, host)
      # node_name
      # puppet_class.name,
      # nodeset_yaml["HOSTS"][node.name]['config'],
      # @repo,
    end

    def run_testsuite
      @testsuite.each { |id, tests|
        run_puppet(tests["instance"], tests["classes"], logger:@logger, reset_after_run:true)
      }
    end

    def enqueue_driver_instance(node_name, run_from)
      config = @nodeset[node_name]["config"]
      driver = @nodeset[node_name]["driver"]
      if @testsuite.has_key?(node_name)
        @logger.debug("#{driver_id} already registered")
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
          di = ::PuppetBox::Driver::Vagrant.new(
            node_name,
            run_from,
            # "#{repo.tempdir}/etc/puppetlabs/code/environments/production",
            logger: @logger,
            config: config,
          )
        else
          raise "PuppetBox only supports driver: 'vagrant' at the moment (requested: #{driver})"
        end

        @testsuite[driver_id] = {
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


    # Print all results to STDOUT
    def print_results
      # print the report summary
      indent = "  "
      puts "\n\n\nSummary\n======="
      summary.each { |node, class_results|
        puts node
        if class_results.class == String
          puts "#{indent}#{class_results}"
        else
          class_results.each { |puppet_class, passed|
            line = "#{indent}#{puppet_class}: #{passed ? "OK": "FAILED"}"
            if passed
              puts line.green
            else
              puts line.red
            end
          }
        end
      }

      puts "Overall acceptance testing result #{overall}"
    end



    # Run puppet using `driver_instance` to execute
    def run_puppet(driver_instance, puppet_classes, logger:nil, reset_after_run:true)
      # use supplied logger in preference to the default puppetbox logger instance
      logger = logger || @logger.logger
      logger.debug("#{driver_instance.node_name} running test for #{puppet_classes}")
      puppet_classes = Array(puppet_classes)
      results = ResultSet.new
      if driver_instance.open
        logger.debug("#{driver_instance.node_name} started")
        if driver_instance.self_test
          logger.debug("#{driver_instance.node_name} self_test OK, running puppet")
          puppet_classes.each{ |puppet_class|
            if results.class_size(driver_instance.node_name) > 0 and reset_after_run
              # purge and reboot the vm - this will save approximately 1 second
              # per class on the self-test which we now know will succeed
              driver_instance.reset
            end
            driver_instance.run_puppet_x2(puppet_class)
            results.save(driver_instance.node_name, puppet_class, driver_instance.result)
          }
          logger.debug("#{driver_instance.node_name} test completed, closing instance")
          driver_instance.close
        else
          raise "#{driver_instance.id} self test failed, unable to continue"
        end
      else
        raise "#{driver_instance.id} failed to start, unable to continue"
      end

      results
    end

  end
end
