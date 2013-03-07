module MojuraAPI

	class SettingsResource < RestResource

		def name
			'Settings'
		end

		def description
			'Resource of settings, which is a core object in Mojura. Settings can be public (readable for everyone) or protected (readable for administrators). Only administrators may update or delete these settings.'
		end

		def uri_id_to_regexp(id_name)
			(id_name == 'key') ? '[a-zA-Z0-9_]+' : super
		end

		def all(params)
			scopes = [:public]
			scopes.push(:protected) if (API.current_user.administrator?)
			return Settings.all(scopes)
		end

		def all_conditions
			{
				description: 'Returns all settings.',
			}
		end

		def put(params)
			raise NoRightsException.new if (!API.current_user.administrator?)
			value = (params.include?(:type)) ? StringConvertor.convert(params[:value], params[:type]) : params[:value]
			level = (params[:is_public]) ? :public : :protected
			Settings.set(params[:key], value, params[:category], level)
			return [value]
		end

		def put_conditions
			{
				description: 'Adds a new setting.',
				attributes: {
					category: {required: false, type: String, description: 'The category of the setting. Default is \'core\'.'},
					key: {required: true, type: String, description: 'The key of the setting.'},
					value: {required: true, type: String, description: 'A string representation of the value of the setting.'},
					type: {required: false, type: String, description: 'The type of the setting, which can be integer, float, string, boolean, hash or array. Default is string.'},
					level: {required: false, type: String, description: 'The level of the setting, which can be \'public\' (readable\) or \'protected\' (admins-only). Default is \'public\'.' },
				}
			}
		end

		def get(params)
			key = params[:ids][0]
			default = params[:default]
			category = params[:category] || :core
			scopes = [:public]
			scopes.push(:protected) if (API.current_user.administrator?)
			return [Settings.get(key, default, category, scopes)]
		end

		def get_conditions
			{
				description: 'Returns a setting.',
				attributes: {
#					key: {required: true, type: String, description: 'The key of the setting'},
					category: {required: false, type: String, description: 'The category of the setting. Default is \'core\'.'}
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
					attributes: self.put_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			result[:attributes].delete(:type)
			return result
		end

		def delete(params)
			raise NoRightsException.new if (!API.current_user.administrator?)
			Settings.unset(params[:key], params[:category])
			return [:success => true]
		end

		def delete_conditions
			{
				description: 'Deletes a setting.',
				attributes: self.put_conditions[:attributes].each { |_, v| v[:required] = false }
			}
		end

	end

	API.register_resource(SettingsResource.new('settings', '', '[key]'))

end