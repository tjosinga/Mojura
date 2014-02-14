module MojuraWebApp

	class NewsArticleView < BaseView

		attr_reader :newsid

		def initialize(options = {})
			@newsid = WebApp.page.request_params[:newsid]
			if newsid.nil?
				data = WebApp.api_call('news').items[(options[:article_type])]
			else
				data = WebApp.api_call("news/#{@newsid}")
			end
			data[:show_title] = !Settings.get_b(:news, :title_as_page_title, false)
			WebApp.page.data[:title] = data[:title].to_s unless data[:show_title]

			super(options, data)
		end

	end

end

