require 'api/resources/users/users.objects'

module MojuraAPI

	class GroupMembersResource < RestResource

		def name
			'Group members'
		end

		def description
			'Show all members of a group'
		end

		def uri_id_to_regexp(id_name)
			return '[0-9a-f]{24}'
		end

		def all(params)
			groupid = params[:ids][0]
			members = Users.new({groupids: groupid})
			return members.to_a(true)
		end

		def all_conditions
			{
				description: 'Returns a list of members of a group.',
			}
		end


	end

	API.register_resource(GroupMembersResource.new('groups', '[groupid]/members', '[groupid]/members'))
end
