$:.unshift File.join(File.dirname(__FILE__), '../lib/mojura/')
require 'test/unit'
require 'api/lib/stringconvertor'

module MojuraAPI

	class StringConvertorTester < Test::Unit::TestCase

		def test_convert
			assert_equal(true, StringConvertor.convert('true', :boolean))
			assert_equal(false, StringConvertor.convert('false', :boolean))

			assert_equal('2014-08-09', StringConvertor.convert('2014-08-09 12:34:56', :date).to_s)
			assert_equal('2014-08-09T12:34:56', StringConvertor.convert('2014-08-09 12:34:56', :datetime).to_s)
			assert_equal('2014-01-09T12:34:56', StringConvertor.convert('2014-01-09 12:34:56', :datetime).to_s)
			assert_equal('12:34:56', StringConvertor.convert('2014-08-09 12:34:56', :time).to_s)
		end

	end

end