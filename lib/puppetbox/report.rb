module PuppetBox
  module Report
    def self.printstuff(stream=$STDOUT)
      # print the report summary
      indent = "  "
      stream.puts "\n\n\nSummary\n======="
      summary.each { |node, class_results|
        puts node
        if class_results.class == String
          stream.puts "#{indent}#{class_results}"
        else
          class_results.each { |puppet_class, passed|
            line = "#{indent}#{puppet_class}: #{passed ? "OK": "FAILED"}"
            if passed
              stream.puts line.green
            else
              stream.puts line.red
            end
          }
        end
      }

      stream.puts "OVERALL STATUS #{overall}"
      overall
    end
  end
end
