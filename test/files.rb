$:.unshift File.join(File.dirname(__FILE__), '..')
require 'test/unit'
require 'test/testing_database'
require 'api/lib/dbobject'
require 'api/resources/users/users.objects'
require 'api/resources/pages/pages.objects'
require 'api/lib/validator'
require 'api/lib/dbobjects_rights'

module MojuraAPI

	class FilesTester < Test::Unit::TestCase
	end

end