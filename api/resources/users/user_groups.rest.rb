module MojuraAPI

	class UserGroupsResource < RestResource

		def name
			'User groups'
		end

		def description
			'Resource of the groups of a user. It\'a core object in Mojura.'
		end

		def uri_id_to_regexp(id_name)
			return (id_name == 'userid') ? "[0-9a-f]{24}|currentuser" : "[0-9a-f]{24}"
		end

		def all(params = {})
			userid = params[:ids][0]
			user = User.new(userid)
			return user.groups.to_a
		end

		def put(params = {})
			userid = params[:ids][0]
			groupid = params[:groupid].to_s
			user = User.new(userid)
			user.subscribe_to_group(groupid)
			user.save_to_db
			return user.groups.to_a
		end

		def delete(params = {})
			userid = params[:ids][0]
			groupid = params[:ids][1].to_s
			STDOUT << "Groupid #{groupid}\n"
			user = User.new(userid)
			user.unsubscribe_from_group(groupid)
			user.save_to_db
			return user.groups.to_a
		end

		def all_conditions
			{
				description: 'Returns all groups of the given user',
			}
		end

		def put_conditions
			{
				description: 'Subscribes the user to the given group',
				attributes: {
					groupid: {required: true, type: BSON::ObjectId, description: 'The id of the group.'},
				}
			}
		end

		def delete_conditions
			{
				description: 'Unsubscribes the user of the given group'
			}
		end

	end

	API.register_resource(UserGroupsResource.new('users', '[userid]/groups', '[userid]/group/[groupid]'))


end