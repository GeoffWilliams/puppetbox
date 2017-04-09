require "puppetbox/version"

module PuppetBox

  def self.run_puppet(driver_instance, puppet_class)
    if driver_instance.open
      if driver_instance.self_test
        driver_instance.run_puppet_x2(puppet_class)
        driver_instance.close
      end
    end
    driver_instance.result
  end

end
