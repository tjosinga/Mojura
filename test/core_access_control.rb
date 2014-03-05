$:.unshift File.join(File.dirname(__FILE__), '../lib/mojura/')

require 'test/unit'
require 'api/lib/datatypes'
require 'api/lib/access_control'

module MojuraAPI

	class MockObject

		@values = {}

		def initialize(options = {})
			@values = options
		end

		# getter and setter for object fields. Database which
		def method_missing(name, *arguments)
			value = arguments[0]
			name = name.to_s
			if name[-1, 1] == '='
				key = name[0..-2]
				@values[key.to_sym] = value if @values.include?(key)
			else
				return @values[name.to_sym]
			end
		end

	end

	class AccessControlTester < Test::Unit::TestCase

		def initialize(name)
			super
			@admin = MockObject.new({
				id: 1,
				firstname: 'Administrator',
				lastname: 'Administrator',
			  is_admin: true,
			  email: 'admin@localhost',
				groupids: []
			})
			@guest = MockObject.new({ groupids: []})
			@user = MockObject.new({
        id: 2,
				firstname: 'A. Normal',
				lastname: 'User',
				is_admin: false,
				email: 'user@localhost',
				groupids: []
			});
			@group_member = MockObject.new({
        id: 3,
				firstname: 'A. Normal',
				lastname: 'User',
				is_admin: false,
				email: 'user@localhost',
				groupids: [10]
			});
			@owner = MockObject.new({
        id: 4,
				firstname: 'A. Normal',
				lastname: 'User',
				is_admin: false,
				email: 'user@localhost',
				groupids: [10]
			});
		end

		def test_object_rights
			# Checks all possible rights
			65535.times { | right |
				newsitem = MockObject.new({ title: 'test', right: right, userids: [4], groupids: [10]})
				assert_equal((right & 8 > 0), AccessControl.has_rights?(RIGHT_CUSTOM, newsitem, @guest))
				assert_equal((right & 4 > 0), AccessControl.has_rights?(RIGHT_READ,   newsitem, @guest))
				assert_equal((right & 2 > 0), AccessControl.has_rights?(RIGHT_UPDATE, newsitem, @guest))
				assert_equal((right & 1 > 0), AccessControl.has_rights?(RIGHT_DELETE, newsitem, @guest))

				right = right >> 4
				assert_equal((right & 8 > 0), AccessControl.has_rights?(RIGHT_CUSTOM, newsitem, @user))
				assert_equal((right & 4 > 0), AccessControl.has_rights?(RIGHT_READ,   newsitem, @user))
				assert_equal((right & 2 > 0), AccessControl.has_rights?(RIGHT_UPDATE, newsitem, @user))
				assert_equal((right & 1 > 0), AccessControl.has_rights?(RIGHT_DELETE, newsitem, @user))

				right = right >> 4
				assert_equal((right & 8 > 0), AccessControl.has_rights?(RIGHT_CUSTOM, newsitem, @group_member))
				assert_equal((right & 4 > 0), AccessControl.has_rights?(RIGHT_READ,   newsitem, @group_member))
				assert_equal((right & 2 > 0), AccessControl.has_rights?(RIGHT_UPDATE, newsitem, @group_member))
				assert_equal((right & 1 > 0), AccessControl.has_rights?(RIGHT_DELETE, newsitem, @group_member))

				right = right >> 4
				assert_equal((right & 8 > 0), AccessControl.has_rights?(RIGHT_CUSTOM, newsitem, @owner))
				assert_equal((right & 4 > 0), AccessControl.has_rights?(RIGHT_READ,   newsitem, @owner))
				assert_equal((right & 2 > 0), AccessControl.has_rights?(RIGHT_UPDATE, newsitem, @owner))
				assert_equal((right & 1 > 0), AccessControl.has_rights?(RIGHT_DELETE, newsitem, @owner))

				assert_equal(true,  AccessControl.has_rights?(RIGHT_CUSTOM, newsitem, @admin))
				assert_equal(true,  AccessControl.has_rights?(RIGHT_READ,   newsitem, @admin))
				assert_equal(true,  AccessControl.has_rights?(RIGHT_UPDATE, newsitem, @admin))
				assert_equal(true,  AccessControl.has_rights?(RIGHT_DELETE, newsitem, @admin))
			}
		end

	end

end