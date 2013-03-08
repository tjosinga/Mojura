$:.unshift File.join(File.dirname(__FILE__), '..')
require 'test/unit'
require 'api/lib/filterparser'

module MojuraAPI

	class FilterParserTester < Test::Unit::TestCase

		def test_parse
			assert_equal({'username' => 'osingat'}, FilterParser.parse('username:osingat'))
			assert_equal({'$and' => [{'username' => 'tjosinga'}, {'username' => 'cosinga'}]}, FilterParser.parse('username:(tjosinga,cosinga)'))
			assert_equal({'$or' => [{'username' => 'tjosinga'}, {'username' => 'cosinga'}]}, FilterParser.parse('username:(tjosinga|cosinga)'))
			assert_equal({'$or' => [{'username' => {'$gt' => 'tjosinga'}}, {'username' => 'cosinga'}]}, FilterParser.parse('username:({gt:tjosinga}|cosinga)'))
			assert_equal({'$and' => [{'username' => 'osingat'}, {'lastname' => 'cosinga'}]}, FilterParser.parse('(username:osingat),(lastname:cosinga)'))
			assert_equal({'$and' => [{'username' => 'osingat'}, {'lastname' => 'Osinga-Albers'}]}, FilterParser.parse('(username:osingat),(lastname:\'Osinga-Albers\')'))
			assert_equal({'username' => {'$in' => %w(osingat hannah)}}, FilterParser.parse('username:{in:(osingat,hannah)}'))

			# assert_equal({"$and" => [{"$or" => [{"username" => {"$gt" => "tjosinga"}}, {"username" => "cosinga"}]}], "lastname" => [{"gt" => "osinga"}]}, FilterParser.parse("username:({gt:tjosinga}|cosinga),lastname:{gt:osinga}"))

		end

	end

end