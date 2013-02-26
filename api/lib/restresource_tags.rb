require 'api/lib/restresource'

module MojuraAPI

	class TagsResource < RestResource

		attr_reader :resource_class

		def initialize(mod, items_path, item_path, resource_class)
			super(mod, items_path, item_path)
			@resource_class = resource_class
		end

		def name
			'Tags'
		end

		def description
			'Tags for the specified resource.'
		end

		def all(params)
			object = self.resource_class.new(params[:ids][0])
			return object.tags
		end

		def all_conditions
			{
				description: 'Returns a list of tags of a specific resource.',
				uri:         @module + '/' + @items_path,
			}
		end

		def put(params)
			object = self.resource_class.new(params[:ids][0])
			object.add_tags(params['tags'].split(','))
			object.save_to_db
			return object.tags
		end

		def put_conditions
			{
				description: 'Adds tags to the specified resource.',
				uri:         @module + '/' + @items_path,
				attributes:  {
					tags: {required: true, type: String, description: 'A tag or multiple tags separated by a comma. Already existing tags will be ignored.'}
				}
			}
		end

		def delete(params)
			object = self.resource_class.new(params[:ids][0])
			object.delete_tags(params['tags'].split(','))
			object.save_to_db
			return object.tags
		end

		def delete_conditions
			{
				description: 'Deletes tags from the specified resource.',
				uri:         @module + '/' + @items_path,
				attributes:  {
					tags: {required: true, type: String, description: 'A tag or multiple tags separated by a comma. Unknown tags will be ignored.'}
				}
			}
		end

	end

end