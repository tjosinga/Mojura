require 'sanitize'

module MojuraWebApp

	class NewsArticleView < BaseView

		attr_reader :newsid

		def initialize(options = {})
			@newsid = WebApp.page.request_params[:newsid]
			if newsid.nil?
				data = WebApp.api_call('news')[:items][0] # TODO: change to options[:article_type]
				data ||= {} # Might be empty
				data[:article_url] = 'news'
				data[:show_title] = true
			else
				data = WebApp.api_call("news/#{@newsid}")
				data[:show_title] = !Settings.get_b(:news, :title_as_page_title, false)
				short_description = Sanitize.clean(data[:content][:html]).split('. ').slice(0, 5).join('. ') + '...' #contain 5 sentences
				short_description = short_description.split(' ').slice(0, 70).join(' ') if (short_description.split(' ').size > 80)

				WebApp.page.data[:title] = data[:title].to_s unless data[:show_title]
				WebApp.page.include_metatag('og:title', data[:title])
				WebApp.page.include_metatag('og:description', short_description)
				WebApp.page.include_metatag('og:type', 'website')
				WebApp.page.include_metatag('og:url', WebApp.page.base_url + "/news/?newsid=#{data[:id]}")
				WebApp.page.include_metatag('og:image', WebApp.page.base_url + "__api/files/#{data[:imageid]}/download") unless data[:imageid].nil? || data[:imageid].empty?
				WebApp.page.include_metatag('og:site_name', Settings.get_s(:title))
			end
			super(options, data)
		end

	end

end

