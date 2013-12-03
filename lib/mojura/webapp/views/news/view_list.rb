module MojuraWebApp

	class NewsListView < BaseView

		def initialize(options = {})
			data = WebApp.api_call('news')
			super(options, data)
		end

	end

end