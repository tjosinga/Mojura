module MojuraWebApp

	class BodyView < BaseView

		def initialize(options = {})
			super(options)
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
					view_array[:classes] = 'page-content-row'
					@content             += WebApp.render_view(view_array)
				}
			end
		end

		def header
		end

		def navbar
			WebApp.render_view(:view => 'navbar', :wrapping => 'nowrap', :classes => 'navbar', :add_span => false)
		end

		def menu
			WebApp.render_view(:view     => 'sitemap', :wrapping => 'simple', :add_span => false,
			                   :settings => {
				                   menu_only:  true,
				                   depth:      WebApp.get_setting(:menu_depth, 1),
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

		def plugins
			return 'plugins'
		end

		def footer
			return 'footer'
		end

		def breadcrumbs
			return 'breadcrumbs'
		end

	end

	WebApp.register_view('body', BodyView, :in_pages => false)

end