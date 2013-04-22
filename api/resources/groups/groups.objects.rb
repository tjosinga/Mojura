require 'api/lib/dbobject'
require 'api/lib/dbobjects'

module MojuraAPI

	class Group < DbObject

		def initialize(id = nil)
			super('groups', id)
		end

		def load_fields
			yield :name, String, :required => true
			yield :description, String, :extended_only => true
		end

	end


	class Groups < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] = {name: 1} if (options[:sort].nil?)
			super('groups', Group, where, options)
		end

	end


end



