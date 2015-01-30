require 'cgi'

module MojuraWebApp

	class SitemapView < BaseView

		def initialize(options = {})

			options ||= {}
			options[:show_admin] = (options.include?(:show_admin) && options[:show_admin])
			options[:root_url] ||= WebApp.page.root_url
			options[:root_url] += '/' if (options[:root_url] != '')
			options[:draggable] = !options[:draggable].is_a?(FalseClass)
			WebApp.page.include_script_link('ext/jquery/jquery-sortable.js')

			if !options[:items].nil?
				pages = options[:items]
			else
				options[:menu_only] = (options[:menu_only])
				options[:depth] ||= options[:menu_only]? 2 : nil
				options[:use_locale] = false
				begin
					pages = WebApp.api_call('pages', options)
				rescue APIException => _
					pages = {}
				end
			end
			options.delete(:items)
			data = { children: pages }
			prepare_node(data, options[:root_url].to_s)
			data[:is_base] = true
			data[:draggable] = options[:draggable]
			super(options, data)
		end

		def prepare_node(node, base_url)
			base_url += '/' unless (base_url.to_s.end_with?('/'))
			page_url = base_url + URI.encode(node[:title].to_s).gsub('%20', '+')
			node[:has_children] = !node[:children].nil? && (node[:children].size > 0)
			node[:is_base] = false # Should only by set on the first node.
			node[:page_url] = page_url
			node[:children].each { | child | prepare_node(child, page_url) } if node[:has_children]
		end

		WebApp.register_view('sitemap', SitemapView)

	end

end