module MojuraWebApp

	class NewsOverviewView < BaseView

		def initialize(options = {})
			data = WebApp.api_call('news')
			data[:article_url] = 'news'
			super(options, data)
		end

	end

end