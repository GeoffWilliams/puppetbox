require 'yaml'

module PuppetBox
  module NodeSet
    NODESET_FILE = "spec/acceptance/nodesets/puppetbox.yaml"
    VERSION_KEY = "puppetbox_nodeset"
    UNDERSTANDS_VERSION = [1]
    REQUIRED_KEYS = ["config", "driver"]

    def self.parse(nodeset_file)
      nodeset_file = nodeset_file || NODESET_FILE

      # parse the yaml file and simplify to human readable errors
      begin
        nodeset = YAML.load(IO.read(nodeset_file))
      rescue Errno::ENOENT
        raise "File not found: #{nodeset_file}"
      rescue Psych::SyntaxError
        raise "Syntax error reading #{nodeset_file}"
      end
      if nodeset.has_key?(VERSION_KEY)
        if UNDERSTANDS_VERSION.include?(nodeset[VERSION_KEY])
          hosts = nodeset["hosts"]
          hosts.each { |node_name, data|
            # check each node has required keys
            REQUIRED_KEYS.each { |required_key|
              if ! data.has_key?(required_key)
                raise "Nodeset file #{nodeset_file} missing required key #{required_key} for node #{node_name}"
              end
            }
          }
        else
          raise "Nodeset file format is #{nodeset[VERSION_KEY]} but PuppetBox only supports versions #{UNDERSTANDS_VERSION}"
        end
      else
        raise "Nodeset file #{nodeset_file} does not contain #{VERSION_KEY} - check syntax"
      end

    end

    #
    #
    #   if nodeset["hosts"][node.name].has_key?('config') and nodeset_yaml["HOSTS"][node.name].has_key?('driver')
    #     test.classes.each { |puppet_class|
    #       logger.info "Acceptance testing #{node.name} #{puppet_class.name}"
    #       summary[node.name][puppet_class.name] = pb.provision_and_test(
    #         nodeset_yaml["HOSTS"][node.name]["driver"],
    #         node.name,
    #         puppet_class.name,
    #         nodeset_yaml["HOSTS"][node.name]['config'],
    #         @repo,
    #       )
    #
    #       overall &= ! summary[node.name][puppet_class.name]
    #     }
    #   else
    #     message = "onceover-nodes.yaml missing `config` or `driver` element for #{node.name} (tests skipped)"
    #     summary[node.name] = message
    #     overall = false
    #   end
    # end

  end
end
