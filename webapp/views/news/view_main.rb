module MojuraWebApp

	class NewsView < BaseView

		attr_reader :newsid

		def initialize(options = {})
			@newsid = WebApp.page.request_params[:newsid]
			if newsid.nil?
				data = WebApp.api_call('news')
			else
				data = WebApp.api_call("news/#{@newsid}")
				WebApp.page.data[:title] = data[:title].to_s
			end
			super(options, data)
		end

	end

	WebApp.register_view('news', NewsView)

end