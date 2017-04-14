require "puppetbox/version"

module PuppetBox

  def self.run_puppet(driver_instance, puppet_class, logger:nil)
    logger = PuppetBox::Logger.new(logger).logger
    logger.debug("#{driver_instance.id} running test for #{puppet_class}")
    if driver_instance.open
      logger.debug("#{driver_instance.id} started")
      if driver_instance.self_test
        logger.debug("#{driver_instance.id} self_test OK, running puppet")
        driver_instance.run_puppet_x2(puppet_class)
        logger.debug("#{driver_instance.id} test completed, closing instance")
        driver_instance.close
      else
        raise "#{driver_instance.id} self test failed, unable to continue"
      end
    else
      raise "#{driver_instance.id} failed to start, unable to continue"
    end
    driver_instance.result
  end

end
