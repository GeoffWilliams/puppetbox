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

    attr_accessor :status
    attr_accessor :messages

    def initialize(status, messages)
      @status   = status
      @messages = messages
    end

    def passed
      @status == PS_OK
    end

  end
end
