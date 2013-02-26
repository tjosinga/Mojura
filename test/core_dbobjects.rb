$:.unshift File.join(File.dirname(__FILE__), '..')
require 'test/unit'
require 'test/testing_database'
require 'api/lib/dbobject'
require 'api/modules/users/users.objects'
require 'api/modules/pages/pages.objects'
require 'api/lib/validator'
require 'api/lib/dbobjects_rights'

module MojuraAPI

	class DbObjectsTester < Test::Unit::TestCase

		def get_users
			@values = {username:  'tjosinga',
			           password:  'test1password',
			           firstname: 'Taco Jan',
			           infix:     '',
			           lastname:  'Osinga',
			           is_admin:  true,
			           email:     'taco@osisoft.nl'}
			user1   = User.new('4fa94dfb78e72374c3000001')
			user1.load_from_hash(@values)

			@values = {username:  'cosinga',
			           password:  'test2password',
			           firstname: 'Chantal',
			           infix:     '',
			           lastname:  'Osinga-Albers',
			           is_admin:  false,
			           email:     'chantal@osisoft.nl'}
			user2   = User.new('4fa94ef778e7237510000001')
			user2.load_from_hash(@values)

			return [user1, user2]
		end

		def test_rights_where
			user1, user2 = self.get_users
			pages        = Pages.new
			assert_equal({'$where' => '(this.right & 0x0004) = 0x0004'}, pages.get_rights_where(User.new))
			assert_equal({}, pages.get_rights_where(user1))
			assert_equal({'$or' => [{'$where' => '(this.right & 0x0040) = 0x0040'}, {'$and' => [{ownerid: '4fa94ef778e7237510000001'}, {'$where' => '(this.right & 0x4000) = 0x4000'}]}]}, pages.get_rights_where(user2))
			user2.groupids = %w(4fa94ef778e7237510000001)
			assert_equal({'$or' => [{'$where' => '(this.right & 0x0040) = 0x0040'}, {'$and' => [{ownerid: '4fa94ef778e7237510000001'}, {'$where' => '(this.right & 0x4000) = 0x4000'}]}, {'$and' => [{'$in' => %w(4fa94ef778e7237510000001)}, {'$where' => '(this.right & 0x0400) = 0x0400'}]}]}, pages.get_rights_where(user2))
		end

	end

end