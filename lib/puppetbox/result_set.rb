module PuppetBox
  class ResultSet
    def initialize
      @results = {}
    end

    def save(node_name, class_name, result)
      # check we didn't make a stupid programming error
      if result.class != ::PuppetBox::Result
        raise "result to save must be instance of PuppetBox::Result"
      end

      # if this is the first set of results for this node then we need to make
      # a hash to contain the results
      if ! @results.has_key?(node_name)
        @results[node_name] = {}
      end

      # We can only run the same class on each node once, if we attempt to do so
      # again,
      if @results[node_name].has_key?(class_name)
        raise "Duplicate results for class #{class_name} detected, You can " \
        "only test the same class once per node.  Check your test configuration"
      else
        @results[node_name][class_name] = result
      end
    end

    def passed?
      ! @results.empty? and
      @results.map { |node_name, class_results_hash|
        class_results_hash.map { |class_name, class_results|
          class_results.passed?
        }.all?
      }.all?
    end

    def results
      @results
    end

    # The count of how many nodes we presently have saved
    def node_size
      @results.size
    end

    # The count of how many classes we presently have saved for a given node
    def class_size(node_name)
      if @results.has_key?(node_name)
        size = @results[node_name].size
      else
        size = 0
      end

      size
    end

    # The count of how many tests this result_set contains for all nodes and
    # classes
    def test_size
      @results.map {|node_name, classes|
        classes.size
      }.reduce(:+) || 0
    end


  end
end
