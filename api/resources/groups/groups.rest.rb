require 'api/lib/restresource'
require 'api/lib/restresource_tags'

module MojuraAPI

	class GroupResource < RestResource

		def name
			'Groups'
		end

		def description
			'A group combines members and rights.'
		end

		def all(params)
			return paginate(params) { |options| Groups.new(self.filter(params), options) }
		end

		def get(params)
			Group.new(params[:ids][0]).to_a
			#TODO: Check rights
		end

		def put(params)
			Group.new.load_from_hash(params).save_to_db.to_a
			#TODO: Check rights
		end

		def post(params)
			return 'post group'
			#TODO: Check rights
		end

		def delete(params)
			group = Group.new(params[:ids][0])
			#TODO: Check rights
			group.delete_from_db
			return [:success => true]
		end

		def all_conditions
			{
				description: 'Returns a list of groups. Use pagination and filtering to make selections.',
				attributes: page_conditions.merge(filter_conditions)
			}
		end

		def get_conditions
			{
				description: 'Returns a group with the specified groupid'
			}
		end

		def put_conditions
			result =
				{
					description: 'Creates a group and returns the object.',
					uri: @module + '/' + @items_path,
					attributes: {
						name: {required: true, type: String, description: 'The name of the group.'},
						description: {required: false, type: String, description: 'A description of the group. The text may be contain UBB codes for markup.'},
					}
				}
			result[:attributes].merge(self.rights_conditions)
			return result
		end

		def post_conditions
			result =
				{
					description: 'Updates a group with the given keys.',
					attributes: self.put_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the group and all its members and rights',
				uri: @module + '/' + @item_path,
			}
		end

	end

	API.register_resource(GroupResource.new('groups', '', '[groupid]'))
	API.register_resource(TagsResource.new('groups', '[groupid]/tags', '[groupid]/tags', Group))
end
