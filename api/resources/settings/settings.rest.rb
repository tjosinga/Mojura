module MojuraAPI

	class SettingsResource < RestResource

		def name
			'Settings'
		end

		def description
			'Resource of settings, which is a core object in Mojura. Public settings are always visible, protected settings only for administrators.'
		end

		def all(params)
			scopes = [:public]
			scopes.push(:protected) if (API.current_user.is_administrator)
			return Settings.all(scopes)
		end

		def all_conditions
			{
				description: 'Returns all settings.',
			}
		end

		def put(params)
			raise NoRightsException.new if (API.current_user.is_administrator)
			level = (params[:is_public]) ? :public : :protected
			Settings.set(params[:key].to_sym, params[:value], params[:category], level)
		end

		def put_conditions
			{
				description: 'Adds a new setting.',
				attributes:  {
					category: {required: false, type: String, description: 'The category of the setting. Default is \'core\''},
					key:      {required: true, type: String, description: 'The key of the setting'},
					value:    {required: true, type: Mixed, description: 'A value of the setting'},
					type:     {required: false, type: String, description: 'The of the setting, which can be integer, float, string, boolean, hash or array'},
					type:     {required: false, type: String, description: 'The value of the setting'},
				}
			}
		end

		def get(params)
			user = User.new(params[:ids][0])
			#TODO: check rights
			return user.to_a
		end

		def get_conditions
			{
				description: 'Returns a setting.',
				attributes:  {
					key:      {required: true, type: String, description: 'The key of the setting'},
					category: {required: false, type: String, description: 'The category of the setting. Default is \'core\''}
				}
			}
		end

		def post(params)
			params[:ids]
			return
		end

		def post_conditions
			result =
				{
					description: 'Updates an setting with a specific value.',
					attributes:  self.put_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			result[:attributes].delete(:type)
			return result
		end

		def delete(params)
			user = User.new(params[:ids][0])
			user.delete_from_db
			return [:success => true]
		end

		def delete_conditions
			{
				description: 'Deletes a setting.',
				attributes:  self.put_conditions[:attributes].each { |_, v| v[:required] = false }
			}
		end

	end

	API.register_resource(SettingsResource.new('settings', '', '[key]'))

end