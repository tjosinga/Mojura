require 'ubbparser'

module MojuraWebApp

	class VideoView < BaseView

		def render
			size = @options[:parent_col_span] || 1
			width = (60 * size) + (20 * (size - 1))
			height = (width * 0.66).ceil + 20
			return WebApp.parse_text("[video width=#{width} height=#{height}]#{options[:url]}[/video]")
		end

		WebApp.register_view('video', VideoView, :min_col_span => 2)

	end


end