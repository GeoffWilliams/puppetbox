require "bundler/setup"
require "puppetbox"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


NODESET_GOOD            = "spec/fixtures/nodesets/good.yaml"
NODESET_INVALID_VERSION = "spec/fixtures/nodesets/invalid_version.yaml"
NODESET_MISSING_CONFIG  = "spec/fixtures/nodesets/missing_config.yaml"
NODESET_MISSING_DRIVER  = "spec/fixtures/nodesets/missing_driver.yaml"
NODESET_BROKEN          = "spec/fixtures/nodesets/broken.yaml"
