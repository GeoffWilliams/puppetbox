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

    # 0: The run succeeded with no changes or failures; the system was already in the desired state.
    # 1: The run failed, or wasn't attempted due to another run already in progress.
    # 2: The run succeeded, and some resources were changed.
    # 4: The run succeeded, and some resources failed.
    # 6: The run succeeded, and included both changes and failures.
    def report(status_code, messages)
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
