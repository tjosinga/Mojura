$:.unshift File.join(File.dirname(__FILE__), '../lib/mojura/')

require 'test/unit'
require 'json'
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
				groupids: [12]
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

		def test_group_rights
			rights = DbObjectRights.int_to_rights_hash(0b00001111000001000100)
			an_object = MockObject.new({ title: 'test', rights: rights, userids: [4], groupids: [10], module: :test_module})

			assert_equal(false, AccessControl.has_rights?(RIGHT_CREATE, an_object, @user))
			assert_equal(true, AccessControl.has_rights?(RIGHT_READ,    an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_UPDATE, an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_DELETE, an_object, @user))

			AccessControl.set_role_right(12, :test_module, :MockObject, RIGHT_CREATE, true);
			assert_equal(true, AccessControl.has_rights?(RIGHT_CREATE,  an_object, @user))
			assert_equal(true, AccessControl.has_rights?(RIGHT_READ,    an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_UPDATE, an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_DELETE, an_object, @user))

			AccessControl.set_role_right(12, :test_module, :MockObject, RIGHT_READ, false);
			assert_equal(true, AccessControl.has_rights?(RIGHT_CREATE,  an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_READ,   an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_UPDATE, an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_DELETE, an_object, @user))

			AccessControl.set_role_right(12, :test_module, :MockObject, RIGHT_READ, nil);
			assert_equal(true, AccessControl.has_rights?(RIGHT_CREATE,  an_object, @user))
			assert_equal(true, AccessControl.has_rights?(RIGHT_READ,    an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_UPDATE, an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_DELETE, an_object, @user))

			AccessControl.set_role_right(12, :test_module, :MockObject, RIGHT_UPDATE, true);
			assert_equal(true, AccessControl.has_rights?(RIGHT_CREATE,  an_object, @user))
			assert_equal(true, AccessControl.has_rights?(RIGHT_READ,    an_object, @user))
			assert_equal(true, AccessControl.has_rights?(RIGHT_UPDATE,  an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_DELETE, an_object, @user))

			AccessControl.set_role_right(12, :test_module, :MockObject, RIGHT_UPDATE, false);
			assert_equal(true, AccessControl.has_rights?(RIGHT_CREATE,  an_object, @user))
			assert_equal(true, AccessControl.has_rights?(RIGHT_READ,    an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_UPDATE, an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_DELETE, an_object, @user))

			AccessControl.set_role_right(12, :test_module, :MockObject, RIGHT_UPDATE, nil);
			assert_equal(true, AccessControl.has_rights?(RIGHT_CREATE,  an_object, @user))
			assert_equal(true, AccessControl.has_rights?(RIGHT_READ,    an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_UPDATE, an_object, @user))
			assert_equal(false, AccessControl.has_rights?(RIGHT_DELETE, an_object, @user))
		end

		def test_object_rights
			# Checks all possible rights
			#0xFFFF.times { | rights |
			0x000F.times { | rights |
				rights_hash = DbObjectRights.int_to_rights_hash(rights)
				an_object = MockObject.new({ title: 'test', rights: rights_hash, userids: [4], groupids: [10], module: 'test_module'})
				assert_equal((rights & 8 > 0), AccessControl.has_rights?(RIGHT_CUSTOM, an_object, @guest))
				assert_equal((rights & 4 > 0), AccessControl.has_rights?(RIGHT_READ,   an_object, @guest))
				assert_equal((rights & 2 > 0), AccessControl.has_rights?(RIGHT_UPDATE, an_object, @guest))
				assert_equal((rights & 1 > 0), AccessControl.has_rights?(RIGHT_DELETE, an_object, @guest))

				rights = rights >> 4
				assert_equal((rights & 8 > 0), AccessControl.has_rights?(RIGHT_CUSTOM, an_object, @user))
				assert_equal((rights & 4 > 0), AccessControl.has_rights?(RIGHT_READ,   an_object, @user))
				assert_equal((rights & 2 > 0), AccessControl.has_rights?(RIGHT_UPDATE, an_object, @user))
				assert_equal((rights & 1 > 0), AccessControl.has_rights?(RIGHT_DELETE, an_object, @user))

				rights = rights >> 4
				assert_equal((rights & 8 > 0), AccessControl.has_rights?(RIGHT_CUSTOM, an_object, @group_member))
				assert_equal((rights & 4 > 0), AccessControl.has_rights?(RIGHT_READ,   an_object, @group_member))
				assert_equal((rights & 2 > 0), AccessControl.has_rights?(RIGHT_UPDATE, an_object, @group_member))
				assert_equal((rights & 1 > 0), AccessControl.has_rights?(RIGHT_DELETE, an_object, @group_member))

				rights = rights >> 4
				assert_equal((rights & 8 > 0), AccessControl.has_rights?(RIGHT_CUSTOM, an_object, @owner))
				assert_equal((rights & 4 > 0), AccessControl.has_rights?(RIGHT_READ,   an_object, @owner))
				assert_equal((rights & 2 > 0), AccessControl.has_rights?(RIGHT_UPDATE, an_object, @owner))
				assert_equal((rights & 1 > 0), AccessControl.has_rights?(RIGHT_DELETE, an_object, @owner))

				assert_equal(true, AccessControl.has_rights?(RIGHT_CUSTOM, an_object, @admin))
				assert_equal(true, AccessControl.has_rights?(RIGHT_READ,   an_object, @admin))
				assert_equal(true, AccessControl.has_rights?(RIGHT_UPDATE, an_object, @admin))
				assert_equal(true, AccessControl.has_rights?(RIGHT_DELETE, an_object, @admin))
			}
		end

	end

end