module MojuraAPI

	class SettingsResource < RestResource

		def name
			'Settings'
		end

		def description
			'Resource of settings, which is a core object in Mojura. Settings can be public (readable for everyone) or protected (readable for administrators). Only administrators may update or delete these settings.'
		end

		def uri_id_to_regexp(id_name)
			(id_name == 'key') || (id_name == 'category') ? '[a-zA-Z0-9_]+' : super
		end

		def all(params)
			scopes = API.current_user.administrator? ? [:private, :protected, :public] : [:public]
			return Settings.all(scopes, true, params[:category])
		end

		def all_conditions
			{
				description: 'Returns all settings.',
				attributes: {
					category: {required: false, type: String, description: 'Only shows the settings of the given category. If none is given, all settings will be returned.'},
				}
			}
		end

		def put(params)
			raise NoRightsException.new unless API.current_user.administrator?
			value = (params.include?(:type)) ? StringConvertor.convert(params[:value], params[:type]) : params[:value]
			level = (params[:level].to_s == 'public') ? :public : :protected
			Settings.set(params[:key], value, params[:category], level)
			return [value]
		end

		def put_conditions
			{
				description: 'Adds a new setting.',
				attributes: {
					category: {required: false, type: String, description: 'The category of the setting. Default is \'core\'.'},
					key: {required: true, type: String, description: 'The key of the setting.'},
					type: {required: false, type: String, description: 'The type of the setting, which can be integer, float, string, boolean, hash or array. Default is string.'},
					level: {required: false, type: String, description: 'Set the level to protected or public. Default is protected.' },
					value: {required: false, type: String, description: 'A string representation of the value of the setting.'}
				}
			}
		end

		def get(params)
			key = params[:ids][1]
			category = params[:ids][0]
			scopes = API.current_user.administrator? ? [:private, :protected, :public] : [:public]
			return scopes #[Settings.getString(key, category, scopes)]
		end

		def get_conditions
			{
				description: 'Returns a setting.',
				attributes: {	}
			}
		end

		#noinspection RubyUnusedLocalVariable
		def post(params)
			key = params[:ids][1]
			category = params[:ids][0]
			value = params[:value]
			Settings.set(key, value, category)
			return [value]
		end

		def post_conditions
			result = {
				description: 'Updates an setting with a specific value. It\'s not possible to update a private setting.',
				attributes: self.put_conditions[:attributes].keep_if { |k, v| v[:required] = false; k == :value }
			}
			return result
		end

		def delete(params)
			raise NoRightsException.new if (!API.current_user.administrator?)
			key = params[:ids][1]
			category = params[:ids][0]
			Settings.unset(key, category)
			return [:success => true]
		end

		def delete_conditions
			{
				description: 'Deletes a setting. It\'s not possible to delete a private setting.',
				attributes: {}
			}
		end

	end

	API.register_resource(SettingsResource.new('settings', '', '[category]/[key]'))

end