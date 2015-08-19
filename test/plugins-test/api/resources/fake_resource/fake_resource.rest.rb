require 'api/resources/locale/locale.object'

module MojuraAPI

	class FakeResource < RestResource

		def name
			'Fake resource.'
		end

		def description
			'Fake resource for testing the plugins manager.'
		end

		def all(params)
			return ['It is working']
		end

		def all_conditions
			{
				description: 'Returns a string',
			}
		end
	end

	API.register_resource(FakeResource.new('fake_resource', ''))

end