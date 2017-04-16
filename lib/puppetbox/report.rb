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

  end
end
