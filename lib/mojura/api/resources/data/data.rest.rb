require 'api/lib/restresource'
require 'api/lib/restresource_tags'
require 'api/lib/exceptions'
require 'api/resources/data/data.objects'

module MojuraAPI

	class DataResource < RestResource

		def name
			'Data blocks'
		end

		def description
			'Resource of data blocks, a basic block of user data, which can be used for all kind of user forms.'
		end

		def all(params)
			raise NoRightsException.new unless API.current_user.administrator?
			params[:pagesize] ||= 25
			result = paginate(params) { |options| DataBlocks.new(self.filter(params), options) }
			return result
		end

		def post(params)
			DataBlock.new.load_from_hash(params).save_to_db.to_h
		end

		def get(params)
			raise NoRightsException.new unless API.current_user.administrator?
			DataBlock.new(params[:ids][0]).to_h
		end

		def put(params)
			raise NoRightsException.new unless API.current_user.administrator?
			datablock = DataBlock.new(params[:ids][0])
			datablock.load_from_hash(params)
			return datablock.save_to_db.to_h
		end

		def delete(params)
			raise NoRightsException.new unless API.current_user.administrator?
			datablock = DataBlock.new(params[:ids][0])
			datablock.delete_from_db
			return [:success => true]
		end

		def all_conditions
			result = {
				description: 'Returns a list of data blocks. Use pagination and filtering to make selections.',
			}
			return result
		end

		def post_conditions
			result = {
				description: 'Creates and returns the data resource.',
				attributes: {
					type: {required: true, type: String, description: 'The type of the data block, a unique identifier for the form.'},
					name: {required: true, type: String, description: 'The name of the user.'},
					email: {required: true, type: String, description: 'The email address of the user.'},
					text: {required: false, type: RichText, description: 'The content of the block in the format. The client is responsible for validating the text.'},
					values: {required: false, type: String, description: 'A hash of keys and their values. The client is responsible for validating the key-values.'},
				}
			}
			return result
		end

		def get_conditions
			{
				description: 'Returns a data resource with the specified dataid',
			}
		end

		def put_conditions
			result =
				{
					description: 'Updates a data resource with the given keys.',
					attributes: self.post_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the data resource'
			}
		end

	end

	API.register_resource(DataResource.new('data', '', '[dataid]'))

end