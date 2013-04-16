$:.unshift File.join(File.dirname(__FILE__), '..')
require 'test/unit'
require 'test/testing_database'
require 'api/lib/dbobject'
require 'api/modules/users/users.objects'
require 'api/lib/validator'

module MojuraAPI

	class DbObjectTester < Test::Unit::TestCase

		def get_user
			@values = {username: 'tjosinga',
			           password: 'test1password',
			           firstname: 'Taco Jan',
			           infix: '',
			           lastname: 'Osinga',
			           email: 'taco@osisoft.nl'}
			user = User.new
			user.load_from_hash(@values)
			return user
		end

		def test_direct_creation
			assert_raise(Exception) { DbObject.new('test') }
		end

		def test_load_from_hash
			# assert_not_equal(@values["password"], user.password)
			user = self.get_user
			assert_equal(@values['username'], user.username)
			assert_equal(@values['firstname'], user.firstname)
			assert_equal(@values['infix'], user.infix)
			assert_equal(@values['lastname'], user.lastname)
			assert_equal(@values['email'], user.email)
		end

		def test_username
			user = self.get_user
			assert_nothing_raised(ValidationError) { user.username = 'tjosinga' }
			assert_nothing_raised(ValidationError) { user.username = 'tjos_inga' }
			assert_nothing_raised(ValidationError) { user.username = 'tjos.inga' }
			assert_nothing_raised(ValidationError) { user.username = 'tjosinga' }
			assert_raise(ValidationError) { user.username = 'tjos/inga' }
			assert_raise(ValidationError) { user.username = 'tjos?inga' }
			assert_raise(ValidationError) { user.username = '' }
			assert_raise(ValidationError) { user.username = nil }
			assert_raise(ValidationError) { user.username = 0 }
			assert_raise(ValidationError) { user.username = 12 }
		end

		def test_save_to_db
			user = self.get_user
			assert_nil(user.id)
			user.save_to_db
			assert_not_nil(user.id)
			assert(!user.changed?)
			user.username = 'osingat'
			assert(user.changed?)
			user.save_to_db
			assert(!user.changed?)
			user.delete_from_db
			assert_nil(user.id)
		end

		def test_load_from_db

		end

	end

end