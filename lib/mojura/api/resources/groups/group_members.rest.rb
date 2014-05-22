require 'api/resources/users/users.objects'

module MojuraAPI

	class GroupMembersResource < RestResource

		def name
			'Group members'
		end

		def description
			'Show all members of a group'
		end

		#noinspection RubyUnusedLocalVariable
		def uri_id_to_regexp(id_name)
			return '[0-9a-f]{24}'
		end

		def all(params)
			groupid = params[:ids][0]
			return paginate(params) { |options| Users.new({groupids: groupid}, options) }
		end

		def all_conditions
			{
				description: 'Returns a list of members of a group.',
			}
		end


	end

	API.register_resource(GroupMembersResource.new('groups', '[groupid]/members'))
end
