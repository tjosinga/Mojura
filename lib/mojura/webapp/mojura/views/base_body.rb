module MojuraWebApp

	class BaseBodyView < BaseView

		def initialize(options = {}, data = {})
			data[:show_navbar] ||= Settings.get_b(:show_navbar)
			data[:show_content_title] ||= Settings.get_b(:show_content_title)

			super(options, data)
			#pre render the content part, which allow setting of the title, etc.
			if WebApp.page.data[:views].nil?
				if (!WebApp.page.data[:view].nil?) && (WebApp.page.data[:view] != 'body')
					@content = WebApp.render_view(:view => WebApp.page.data[:view], :classes => 'page-content-row')
				else
					@content = WebApp.page.data[:error].to_s rescue ''
				end
			else
				@content = ''
				WebApp.page.data[:views].each { |view_array|
					view_array[:may_edit_view] = WebApp.page.data[:rights][:allowed][:update] rescue false
					view_array[:classes] = 'page-content-row'
					@content += WebApp.render_view(view_array)
				}
			end
		end

		def header
		end

		def navbar
			WebApp.render_view(:view => 'navbar', :wrapping => 'nowrap', :classes => 'navbar', :add_span => false)
		end

		def menu
			WebApp.render_view(:view => 'sitemap', :wrapping => 'simple', :add_span => false,
			                   :settings => {
				                   menu_only: true,
				                   depth: Settings.get_i(:menu_depth, :core, 1),
				                   show_admin: false})
		end

		def page_editor
			PageEditView.new({}).render
		end

		def page_title
			WebApp.page.title
		end

		def content_title
			WebApp.page.data[:title].to_s
		end

		def content
			@content
		end

		def is_home
			WebApp.page.is_home
		end

	end

end