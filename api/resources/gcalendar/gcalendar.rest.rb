require 'google/api_client'

module MojuraAPI

	class GCalendarResource < RestResource

		def name
			'Google Calendar'
		end

		def description
			'Resource for Google Calendar'
		end

		def all(params)
		end

		def all_conditions
			{
				description: 'Returns all Google Calendar for specified account.',
				attributes: { }
			}
		end



	end

	API.register_resource(
		Resource.new('gcalendar', '', '[category]/[key]'))

end