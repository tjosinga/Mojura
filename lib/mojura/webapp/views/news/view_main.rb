require 'webapp/views/news/view_list'
require 'webapp/views/news/view_article'
require 'webapp/views/news/view_overview'

module MojuraWebApp

	class NewsView < BaseView

		def initialize(options = {}, data = {})
			if WebApp.current_user.logged_in?
				WebApp.page.include_template_file('template-news-addedit', 'webapp/views/news/view_add_edit.mustache')
				WebApp.page.include_template_file('template-news-delete', 'webapp/views/news/view_delete.mustache')
				options[:uses_editor] = true
			end
			WebApp.page.include_script_link('ext/moment/moment-with-langs.min.js')
      super(options, data);
		end

		def render
			type = @options[:type].to_s
			newsid = WebApp.page.request_params[:newsid].to_s
			if type == 'list'
				view = NewsListView.new(@options)
			elsif (type == 'article') || (type.empty? && !newsid.empty?)
				view = NewsArticleView.new(@options)
			else
				view = NewsOverviewView.new(@options)
			end
			return view.render
		end

		WebApp.register_view('news', NewsView)

	end


end