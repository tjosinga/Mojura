require 'api/lib/restresource'
require 'api/lib/restresource_tags'
require 'api/resources/locations/locations.objects'

module MojuraAPI

	class LocationsResource < RestResource

		def name
			'Locations'
		end

		def description
			'Resource of locations'
		end

		def all(params)
			return Locations.new().to_a;
		end

		def post(params)
			Location.new.load_from_hash(params).save_to_db.to_a
		end

		def get(params)
			Location.new(params[:ids][0]).to_a
		end

		def put(params)
			location = Location.new(params[:ids][0])
			location.load_from_hash(params)
			return location.save_to_db.to_a
		end

		def delete(params)
			location = Location.new(params[:ids][0])
			location.delete_from_db
			return [:success => true]
		end

		def all_conditions
			result = {
				description: 'Returns a list of locations.',
				attributes: {
				}
			}
			result[:attributes].merge(self.filter_conditions)
			return result
		end

		def post_conditions
			result = {
				description: 'Creates a location and returns the resource.',
				attributes: {
					title: {required: true, type: String, description: 'The title of the location.'},
					latitude: {required: false, type: Float, description: 'The latitude of the location.'},
					longitude: {required: false, type: Float, description: 'The longitude of the location.'},
					address: {required: false, type: String, description: 'The address of the location. This address will be converted to a latitude or longitude. If the search fails, the server responds with a server error and nothing is saved.'},
					category: {required: false, type: String, description: 'The category of the location.'},
					description: {required: false, type: RichText, description: 'The description of the item in the format.'},
					language: {required: false, type: String, description: 'The language of the description.'},
					format_type: {required: false, type: String, description: 'The formatting type of the description, which could be \'ubb\' (default), \'html\' or \'plain\'.'},
				}
			}
			return result
		end

		def get_conditions
			{
				description: 'Returns a location with the specified locationid',
			}
		end

		def put_conditions
			result =
				{
					description: 'Updates a location with the given keys.',
					attributes: self.post_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the location.'
			}
		end

	end

	API.register_resource(LocationsResource.new('locations', '', '[locationid]'))

end