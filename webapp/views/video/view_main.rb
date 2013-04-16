require 'ubbparser'

module MojuraWebApp

	class VideoView < BaseView

		def render
			return WebApp.parse_text("[video width=100%]#{options[:url]}[/video]")
		end

		WebApp.register_view('video', VideoView, :min_col_span => 2)

	end


end