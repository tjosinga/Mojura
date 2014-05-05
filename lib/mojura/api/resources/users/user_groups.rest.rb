module MojuraAPI

	class UserGroupsResource < RestResource

		def name
			'User groups'
		end

		def description
			'Resource of the groups of a user. It\'s a core object in Mojura.'
		end

		#noinspection RubyUnusedLocalVariable
		def uri_id_to_regexp(id_name)
			return '[0-9a-f]{24}'
		end

		def all(params = {})
			userid = params[:ids][0]
			user = User.new(userid)
			raise NoRightsException.new unless user.current_user_has_right?(RIGHT_READ)
			return user.groups.to_a
		end

		def put(params = {})
			userid = params[:ids][0]
			user = User.new(userid)
			raise NoRightsException.new unless user.current_user_has_right?(RIGHT_UPDATE)
			user.subscribe_to_group(groupid)

			groupid = params[:groupid].to_s
			group = Group.new(groupid)
			raise NoRightsException.new unless group.current_user_has_right?(RIGHT_SUBSCRIBE)

			user.save_to_db
			return user.groups.to_a
		end

		def delete(params = {})
			userid = params[:ids][0]
			user = User.new(userid)
			raise NoRightsException.new unless user.current_user_has_right?(RIGHT_UPDATE)

			groupid = params[:ids][1].to_s
			group = Group.new(groupid)
			raise NoRightsException.new unless group.current_user_has_right?(RIGHT_SUBSCRIBE)

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