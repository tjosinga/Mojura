
module MojuraWebApp

	class PostsView < BaseView

		def initialize(options = {})
			data = WebApp.api_call('posts')
			STDOUT << JSON.pretty_generate(data) + "\n"
			super(options, data)
			WebApp.page.include_template_file('template_posts_posts', 'webapp/views/posts/view_posts.mustache')
			WebApp.page.include_template_file('template_posts_message', 'webapp/views/posts/view_message.mustache')
			WebApp.page.include_template_file('template_posts_add_edit', 'webapp/views/posts/view_add_edit.mustache')
			WebApp.page.include_script_link('ext/moment/moment-with-locales.min.js')
			WebApp.page.include_locale('posts');
		end

		def has_more
			@data[:pageinfo][:current] < @data[:pageinfo][:pagecount]
		end

		WebApp.register_view('posts', PostsView)

	end


end