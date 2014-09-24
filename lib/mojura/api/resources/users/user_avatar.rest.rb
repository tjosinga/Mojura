module MojuraAPI

	class UserAvatarResource < RestResource

		def name
			'User avatar'
		end

		def description
			'Resource of the avatar of a user. It\'s a core object in Mojura.'
		end

		#noinspection RubyUnusedLocalVariable
		def uri_id_to_regexp(id_name)
			return '[0-9a-f]{24}'
		end

		def get(params = {})
			userid = params[:ids][0]
			user = User.new(userid)
			return API.send_file(user.avatar_filename, :filename => user.username + '.jpg', :mime_type => 'image/jpeg')
		end

		def put(params = {})
			userid = params[:ids][0]
			user = User.new(userid)
			user.save_avatar(params[:file][:tempfile].path, params[:file][:type]) if params[:file].is_a?(Hash)
			return [user.to_h[:avatar]]
		end

		def delete(params = {})
			userid = params[:ids][0]
			user = User.new(userid)
			user.delete_avatar
			return [user.to_h[:avatar]]
		end

		def get_conditions
			{
				description: 'Returns an image file containing the avatar of the given user.',
			}
		end

		def put_conditions
			{
				description: 'Adds a new avatar to the given user.',
				attributes: {
					file: {required: true, type: File, description: 'An image file. This file will be '},
				}
			}
		end

		def delete_conditions
			{
				description: 'Deletes the avatar of the given user.'
			}
		end

	end

	API.register_resource(UserAvatarResource.new('users', nil, '[userid]/avatar'))

end