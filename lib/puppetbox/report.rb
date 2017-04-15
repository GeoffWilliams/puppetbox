module PuppetBox
  module Report
    def self.printstuff
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

      puts "OVERALL STATUS #{overall}"
      overall
    end
  end
end
