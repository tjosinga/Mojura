module MojuraWebApp

	class NewsArticleView < BaseView

		attr_reader :newsid

		def initialize(options = {})
			@newsid = WebApp.page.request_params[:newsid]

			if newsid.nil?
				data = WebApp.api_call('news')
			else
				data = WebApp.api_call("news/#{@newsid}")
				data[:show_title] = !Settings.get_b(:news, :title_as_page_title, false)
				WebApp.page.data[:title] = data[:title].to_s unless data[:show_title]
			end

			data[:show_overview] = (options[:type] == 'overview')
			data[:show_list] = (options[:type] == 'list')
			data[:show_article] = (options[:type] == 'article')

			super(options, data)
		end

	end

end

