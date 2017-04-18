module PuppetBox
  module Util


    # return the filename that a testcase for a particular test should live in
    # eg node_name=centos7, test_name=role::base should be in centos7/role__base.pp
    def self.test_file_name(node_name, test_name)
      test_name_safe = test_name.gsub(/::/,'__')
      File.join(node_name, "#{test_name_safe}.pp")
    end

  end
end
