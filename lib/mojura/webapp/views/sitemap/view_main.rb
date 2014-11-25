require 'cgi'

module MojuraWebApp

	class SitemapView < BaseView

		def initialize(options = {})
			WebApp.page.include_script_link('ext/jquery/jquery-sortable.js')

			options ||= {}
			options[:show_admin] = (options.include?(:show_admin) && options[:show_admin])
			options[:root_url] ||= WebApp.page.root_url
			options[:root_url] += '/' if (options[:root_url] != '')

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
			prepare_node(data)
			data[:is_base] = true
			super(options, data)
		end

		def prepare_node(node)
			node[:has_children] = !node[:children].nil? && (node[:children].size > 0)
			node[:is_base] = false # Should only by set on the first node.
			node[:children].each { | child | prepare_node(child) } if node[:has_children]
		end

		WebApp.register_view('sitemap', SitemapView)

	end

end