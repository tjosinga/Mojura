$:.unshift File.join(File.dirname(__FILE__), '../lib/mojura/')
require 'test/unit'
require 'api/lib/datatypes'

module MojuraAPI

	class HashTester < Test::Unit::TestCase

		def test_flatten_hash
			src = {
				test1: 'test1',
		    test2: ['test2a', 'test2b'],
			  test3: {
				  a: 'test3a',
			    b: 'test3b'
			  }
			}

			dest1 = {
				test1: 'test1',
				test2: "test2a\ntest2b",
				'test3.a'.to_sym => 'test3a',
				'test3.b'.to_sym => 'test3b'
			}
			dest2 = {
				test1: 'test1',
				test2: 'test2a,test2b',
				'test3/a'.to_sym => 'test3a',
				'test3/b'.to_sym => 'test3b'
			}

			assert_equal(dest1, src.flatten_hash)
			assert_equal(dest2, src.flatten_hash('/', ','))

			src.flatten_hash!
			assert_equal(dest1, src)
		end

	end

end