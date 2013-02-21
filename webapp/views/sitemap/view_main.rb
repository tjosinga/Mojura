require 'uri'

module MojuraWebApp

	class SitemapView < BaseView

		attr_reader :pages, :index

		def initialize(options = {})
			@index = 0
			options ||= {}
			options[:show_admin] = (options.include?(:show_admin) && options[:show_admin])
			options[:root_url] ||= ''
			options[:root_url] += '/' if (options[:root_url] != '')
      if !options[:items].nil?
        @pages = options[:items]
      else
        options[:depth] ||= 2
        options[:menu_only] = (options[:menu_only])

        begin
          @pages = WebApp.api_call('pages', {menu_only: options[:menu_only], depth: options[:depth]})
        rescue APIException => _
          @pages = {}
        end
      end
			options.delete(:items)
			super(options, @pages)
		end

		def html_class
			@options[:class]
		end

		def has_pages
			(!@pages.nil?) && (@pages.size > 0)
		end

		def subpages
			if @pages[@index].has_key?(:children)
				suboptions = {}
				suboptions[:items] = @pages[@index][:children]
				suboptions[:show_admin] = @options[:show_admin]
				suboptions[:root_url] = @options[:root_url] + URI.encode(@pages[@index][:title])
				return SitemapView.new(suboptions).render
			end
		end

		def page_url
			@options[:root_url] + URI.encode(@pages[@index][:title])
		end

		def inc_index
			@index += 1
			return nil
		end

		def admin_icons
	#		if (@options[:show_admin]
		end

		WebApp.register_view('sitemap', SitemapView)

	end

end