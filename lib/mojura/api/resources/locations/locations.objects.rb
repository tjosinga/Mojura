require 'digest'
require 'api/lib/dbobjects'
require 'api/resources/groups/groups.objects'

module MojuraAPI

	class Location < DbObject

		def initialize(id = nil)
			super('locations', id)
		end

		def load_fields
			yield :title, String, :required => true
			yield :latitude, Float, :required => true
			yield :longitude, Float, :required => true
			yield :category, String, :required => false, :validations => {matches_regexp: /^[a-zA-Z]+[\w\.-]*$/}
			yield :description, RichText, :required => false
		end

	end


	class Locations < DbObjects

		def initialize(where = {}, options = {})
			super('locations', Location, where, options)
		end

	end


end



