require 'SecureRandom'

module MojuraAPI

	class Grave < DbObject

		def initialize(id = nil)
			super('graves', id)
		end

		def load_fields
			yield :location, String, :required => true
			yield :depth, Integer, :required => true, :default => 2
			yield :state, Integer, :default => 0
			yield :currently_buried, Integer, :default => 0
			yield :owners, Hash, :default => {}, :extended_only => true
			yield :buried, Hash, :default => {}, :extended_only => true
		end

		def add_owner(name, address, postal_code, city, phone = nil, email = nil, agreement = :maintenance, years = 1)
			item[:name] = name
			item[:address] = address
			item[:postal_code] = postal_code
			item[:city] = city
			item[:phone] = phone
			item[:email] = email
			item[:agreement] = agreement
			item[:years] = years
			id = SecureRandom.hex(16)
			self.owners[id] = item
		end

		def edit_owner(ownerid, values = {})

		end

		def delete_owner(ownerid)
		end

	end


	class Graves < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {timestamp: -1}
			super('graves', Grave, where, options)
		end

	end


end



