require 'cgi'

module MojuraWebApp

	class NavBarView < BaseView

		attr_reader :brand_name, :pages, :index, :options

		def initialize(options = {})
			@index = 0
			@brand_name = (options[:brand_name] || 'Mojura Development')
			options[:show_admin] |= (options.include?(:show_admin) && options[:show_admin])
			options[:root_url] ||= ''
			options[:root_url] += '/' if (options[:root_url] != '')
      if !options[:items].nil?
        @pages = options[:items]
      else
        options[:depth] ||= 2
        options[:menu_only] = (options.include?(:menu_only) && options[:menu_only])
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
				options[:items] = @pages[@index][:children]
				options[:show_admin] = @options[:show_admin]
				options[:root_url] = @options[:root_url] + URI.encode(@pages[@index][:title])
				return SitemapView.new(@options).render
			end
		end

		def page_url
			@options[:root_url] + CGI.escape(@pages[@index][:title])
		end

		def inc_index
			@index += 1
			return nil
		end

		WebApp.register_view('navbar', NavBarView, :in_pages => false)

	end

end