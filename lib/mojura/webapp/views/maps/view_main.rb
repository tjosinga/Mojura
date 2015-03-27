module MojuraWebApp

	class MapsView < BaseView

		def initialize(options = {})
			WebApp.page.include_script_link('ext/leaflet/leaflet.js')
			WebApp.page.include_style_link('ext/leaflet/leaflet.css')
			data = {}
			data[:height] = options[:height] || '300px';
			data[:zoom] = options[:zoom]
			data[:disable_scrollwheel] = options[:disable_scrollwheel]
			data[:tile_url] = options[:tile_url] || Settings.get_s(:tile_url, :maps)
			data[:tile_attribution] = options[:tile_attribution] || Settings.get_s(:tile_attribution, :maps).gsub("\"", "\\\"")
			if WebApp.current_user.logged_in?
				WebApp.page.include_template_file('template-maps-addedit', 'webapp/views/maps/view_add_edit.mustache')
				WebApp.page.include_template_file('template-maps-delete', 'webapp/views/maps/view_delete.mustache')
				WebApp.page.include_locale(:system)
				WebApp.page.include_locale(:maps)
				options[:uses_editor] = true
				data[:show_admin] = true
			end
			super(options, data)
		end

	end

	WebApp.register_view('maps', MapsView)

end