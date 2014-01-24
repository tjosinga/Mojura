require 'cgi'

module MojuraWebApp

	class NavBarView < BaseView

		attr_reader :brand_name, :pages, :index, :options

		def initialize(options = {})
			@index = 0
			@brand_name = (options[:brand_name] || Settings.get_s(:brand_name))
			@brand_name = 'Mojura Development' if @brand_name.empty?
			options[:show_admin] |= (options.include?(:show_admin) && options[:show_admin])
			options[:root_url] ||= ''
			options[:root_url] += '/' if (options[:root_url] != '')
			options[:show_page_editor] = Settings.get_b(:navbar_show_page_editor)
			if !options[:items].nil?
				@pages = options[:items]
			else
				options[:depth] ||= 2
				options[:menu_only] = true unless options.include?(:menu_only)
				begin
					@pages = WebApp.api_call('pages', {menu_only: options[:menu_only], depth: options[:depth]})
				rescue APIException => _
					@pages = {}
				end
			end
			@pages.each { | page |
				page[:menu_title] = page[:title] if page[:menu_title].to_s.empty?
				page[:active] = (page[:id] === WebApp.page.pageid)
			}
			options.delete(:items)
			super(options)
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

		def page_editor
			PageEditView.new({}).render
		end

		def inc_index
			@index += 1
			return nil
		end

		WebApp.register_view('navbar', NavBarView, :in_pages => false)

	end

end