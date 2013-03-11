require 'api/resources/locale/locale.object'

module MojuraAPI

	class LocaleResource < RestResource

		def name
			'Locale'
		end

		def description
			'Resource of locale settings, which is a core object in Mojura. Though localization is the responsibility of the client, the API still needs some locale strings, i.e. sending emails or generating documents. Locale strings may be overriden by saving single items.'
		end

		def uri_id_to_regexp(id_name)
			(id_name == 'key') || (id_name == 'mod_name') ? '[a-zA-Z0-9_]+' : super
		end

		def all(params)
			return Locale.all
		end

		def all_conditions
			{
				description: 'Returns all locale strings.',
			}
		end
	end

	API.register_resource(LocaleResource.new('locale', '', '[mod_name]/[key]'))

end