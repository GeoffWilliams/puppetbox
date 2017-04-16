require 'colorize'
module PuppetBox
  module Report
    def self.pretty_status(passed)
      passed ? 'OK'.green: 'FAILED'.red
    end

    def self.print(result_set, stream=$stdout)
      # print the report summary
      indent = "  "
      stream.puts "\n\n\nSummary\n======="
      result_set.results.each { |node, class_results|
        stream.puts node
        if class_results.class == String
          stream.puts "#{indent}#{class_results}"
        else
          class_results.each { |puppet_class, result|
            stream.puts "#{indent}#{puppet_class}: #{pretty_status(result.passed?)}"
          }
        end
      }

      stream.puts "\n\nOVERALL STATUS: #{pretty_status(result_set.passed?)}"
    end


    # Print an individual test's result or if it failed, it's errors.
    def self.log_test_result_or_errors(logger, node_name, puppet_class, result)
      indent = "  "
      tag = "#{indent}#{node_name} - #{puppet_class}"
      logger.info("#{tag}: #{pretty_status(result.passed?)}")
      if ! result.passed?
        # since we stop running on failure, the error messages will be in the
        # last element of the result.messages array (tada!)
        messages = result.messages
        if messages.empty?
          logger.error "#{tag} - no output available"
        else
          messages[-1].each { |line|
            logger.error "#{tag} - #{line}"
          }
        end
      end
    end

  end
end
