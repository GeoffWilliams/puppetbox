module PuppetBox
  class Result

    #
    # Indicators of overall puppet status
    #

    # OK - no errors encountered
    PS_OK              = 0

    # Puppet indicicated changes made on second run
    PS_NOT_IDEMPOTENT  = 1

    # Error(s) encountered while running puppet
    PS_ERROR           = 2

    def initialize()
      @report = []
    end

    def report(status, messages)
      @report.push({:status => status, :messages => messages})
    end

    def passed
      passed = true
      @report.each { |r|
        passed &= r[:status] == PS_OK
      }

      passed
    end

    def messages(run=-1)
      messages = []
      if run < 0
        # all runs concatenated
        @report.each { |r|
          messages << r[:messages]
        }
      else
        if run < @report.size
          messages << @report[run][:messages]
        else
          raise "Report at index #{run} does not exist, #{@report.size} reports available"
        end
      end
      messages
    end
  end
end
