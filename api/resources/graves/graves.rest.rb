require 'api/lib/restresource'
require 'api/resources/graves/graves.objects'

module MojuraAPI

	class GraveResource < RestResource

		def name
			'Grave'
		end

		def description
			'Resource of graves'
		end

		def all(params)
			if (params[:import] == 'true')
				require 'api/resources/graves/importer'
			end
			params[:pagesize] ||= 100
			result = paginate(params) { |options| Graves.new(self.filter(params), options) }
			return result
		end

		def put(params)
			Grave.new.load_from_hash(params).save_to_db.to_a
		end

		def get(params)
			Grave.new(params[:ids][0]).to_a
		end

		def post(params)
			grave = Grave.new(params[:ids][0])
			grave.load_from_hash(params)
			return grave.save_to_db.to_a
		end

		def delete(params)
			grave = Grave.new(params[:ids][0])
			grave.delete_from_db
			return [:success => true]
		end

		def all_conditions
			result = {
				description: 'Returns a list of graves. Use pagination and filtering to make selections.',
				attributes: {}
			}
			result[:attributes].merge(self.filter_conditions)
			return result
		end

		def put_conditions
			result = {
				description: 'Creates a grave and returns the object.',
				attributes: {
					location: {required: true, type: String, description: 'The location of the grave.'},
					depth: {required: false, type: Integer, description: 'The depth of the grave.'},
					currently_buried: {required: false, type: Integer, description: 'The amount of people currently buried in this grave.'},
				}
			}
			return result
		end

		def get_conditions
			{
				description: 'Returns a grave with the specified graveid',
			}
		end

		def post_conditions
			result =
				{
					description: 'Updates a grave with the given keys.',
					attributes: self.put_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the grave'
			}
		end

	end

	API.register_resource(GraveResource.new('graves', '', '[graveid]'))

end