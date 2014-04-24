require 'api/lib/restresource'
require 'api/resources/users/users.objects'
require 'api/resources/users/user_groups.rest'
require 'api/resources/users/user_avatar.rest'

module MojuraAPI

	class UserResource < RestResource

		def name
			'Users'
		end

		def description
			'Resource of users, which is a core object in Mojura.'
		end

		def all(params)
			return paginate(params) { |options| Users.new(self.filter(params), options) }
		end

		def all_conditions
			{
				description: 'Returns a list of users. Use pagination and filtering to make selections.',
				attributes: page_conditions.merge(filter_conditions)
			}
		end

		def put(params)
			#TODO: check rights
			raise NoRightsException.new unless API.current_user.has_global_right?(:users, :add_users)
			User.new.load_from_hash(params).save_to_db.to_a
		end

		def put_conditions
			{
				description: 'Creates a user and returns the object.',
				attributes: {
					username: {required: true, type: String, description: 'The username for the user. Must be unique.'},
					password: {required: false, type: String, description: 'A password for the user, encoded as a digest (MD5([username]:[realm]:[password])).'},
					firstname: {required: true, type: String, description: 'The first name of the user.'},
					infix: {required: false, type: String, description: 'The infix of the user.'},
					lastname: {required: true, type: String, description: 'The last name of the user.'},
					email: {required: true, type: String, description: 'The email address of the user.'},
					is_admin: {required: false, type: Boolean, description: 'A boolean wether the user is an admin and has all rights.'}
				}
			}
		end

		def get(params)
			user = User.new(params[:ids][0])
			user.user_has_right?(RIGHT_READ)
			return user.to_a
		end

		def get_conditions
			{
				description: 'Returns an user with the specified userid'
			}
		end

		def post(params)
			user = User.new(params[:ids][0])
			raise NoRightsException.new unless user.user_has_right?(RIGHT_UPDATE)
			params.delete(:username); # usernames may not be updated
			params.delete(:password); # password may not be updated directly, only via new_password
			if params.include?(:new_password)
				if !API.current_user.administrator?
					raise MissingParamsException.new(:old_password) if (!params.include?(:old_password)
					raise HTTPException.new('Old password is incorrect') if (params[:old_password] == user.digest))
				end
				params[:password] = params[:new_password]
			end
			user.load_from_hash(params)
			return user.save_to_db.to_a
		end

		def post_conditions
			result =
				{
					description: 'Updates an user with the given keys. A username may not be updated.',
					attributes: self.put_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			result[:attributes].delete(:password)
			result[:attributes][:old_password] = {required: false, type: String, description: 'The digest of the old password. Is required if the authenticated user is not an administrator.'}
			result[:attributes][:new_password] = {required: false, type: String, description: 'The digest of the new password.'}
			return result
		end

		def delete(params)
			user = User.new(params[:ids][0])
			raise NoRightsException.new unless user.user_has_right?(RIGHT_DELETE)
			user.delete_from_db
			return [:success => true]
		end

		def delete_conditions
			{
				description: 'Archives the user, keeping the name for references.'
			}
		end

	end

	API.register_resource(UserResource.new('users', '', '[userid]'))

end