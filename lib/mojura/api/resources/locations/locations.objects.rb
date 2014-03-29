require 'digest'
require 'geocoder'
require 'api/lib/dbobjects'
require 'api/resources/groups/groups.objects'

module MojuraAPI

	class InvalidAddressLocationException < HTTPException
		def initialize(address)
			super("Couldn't find coordinates for the address '#{address}'", 412)
		end
	end

	class Location < DbObject

		def initialize(id = nil)
			super('locations', id)
		end

		def load_fields
			yield :title, String, :required => true, :searchable => true, :searchable_weight => 3
			yield :latitude, Float, :required => true, :default => 0
			yield :longitude, Float, :required => true, :default => 0
			yield :category, String, :required => false, :validations => {matches_regexp: /^[a-zA-Z]+[\w\.-]*$/}
			yield :description, RichText, :required => false, :searchable => true
			yield :address, String, :required => false
		end

		def load_from_hash(values, silent = false)
			if !silent && !values[:address].nil? && !values[:address].empty? && values[:address] != address
				values[:latitude], values[:longitude] = Geocoder.coordinates(values[:address])
				raise InvalidAddressLocationException.new(values[:address]) if values[:latitude].nil?
			end
			super
		end

	end


	class Locations < DbObjects

		def initialize(where = {}, options = {})
			super('locations', Location, where, options)
		end

	end


end



