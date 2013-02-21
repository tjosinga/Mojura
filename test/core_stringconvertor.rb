$:.unshift File.join(File.dirname(__FILE__), '..')
require 'test/unit'
require 'api/lib/stringconvertor'

module MojuraAPI

  class StringConvertorTester < Test::Unit::TestCase

    def test_in_array
      # assert(Validator.in_array("test", ["test", "test 2"]))
      # assert(!Validator.in_array("test", ["test 1", "test 2"]))
      # assert(Validator.in_array(5, [1, 1, 2, 3, 5, 8]))
      # assert(!Validator.in_array(6, [1, 1, 2, 3, 5, 8]))
      # assert(!Validator.in_array("test", []))
      # assert(!Validator.in_array("test", nil))
      # assert(!Validator.in_array("test", {"test" => "test"}))
      # assert(!Validator.in_array("test", {"test" => "test 1"}))
      # assert(!Validator.in_array([2, 5], [1, 1, 2, 3, 5, 8]))
      # assert(Validator.in_array([2, 5], [[1, 1], [2, 5]]))
      # assert(!Validator.in_array([6, 5], [1, 1, 2, 3, 5, 8]))
      # assert(!Validator.in_array([6, 5], nil))
    end

  end

end