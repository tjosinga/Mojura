module MojuraWebApp

	class MapsView < BaseView

		def initialize(options = {})
			WebApp.page.include_script_link('ext/leaflet/leaflet.js')
			WebApp.page.include_style_link('ext/leaflet/leaflet.css')
			data = {};
			data[:height] = options[:height] || '300px';
			super(options, data)
		end



	end

	WebApp.register_view('maps', MapsView)

end