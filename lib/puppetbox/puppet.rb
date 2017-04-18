module PuppetBox
  module Puppet
    def self.include_class(class_name, pre:nil)
      if pre
        # apply a prerequisite and make sure there is a trailing newline.  this
        # will be eval'ed directly so make sure there are no mad characters
        pre = "#{pre}\n"
      end
      "#{pre}include #{class_name}"
    end
  end
end
