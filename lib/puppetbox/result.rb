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

    # Puppet exit codes:
    # 0: The run succeeded with no changes or failures; the system was already in the desired state.
    # 1: The run failed, or wasn't attempted due to another run already in progress.
    # 2: The run succeeded, and some resources were changed.
    # 4: The run succeeded, and some resources failed.
    # 6: The run succeeded, and included both changes and failures.
    def save(status_code, messages)

      # messages will usually be an array of output - one per line, but it might
      # not be and everthing expects to be so just turn it into one if it isn't
      # already...
      messages = Array(messages)
      status = PS_ERROR
      if @report.empty?
        # first run
        if status_code == 0 or status_code == 2
          status = PS_OK
        end
      else
        if status_code == 0
          status = PS_OK
        elsif status_code == 2
          status = PS_NOT_IDEMPOTENT
        end
      end
      @report.push({:status => status, :messages => messages})
    end

    # Test whether this set of results passed or not
    # @return true if tests were executed and passed, nil if no tests were
    #   executed, false if tests were exectued and there were failures
    def passed?
      passed = nil
      @report.each { |r|
        if passed == nil
          passed = (r[:status] == PS_OK)
        else
          passed &= (r[:status] == PS_OK)
        end
      }

      passed
    end

    def report_count
      @report.size
    end

    def report_message_count(report)
      @report[report].messages.size
    end



    def messages(run=-1)
      messages = []
      if run < 0
        # all NESTED in order of report
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
