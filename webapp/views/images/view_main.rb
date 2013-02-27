require 'ubbparser'

module MojuraWebApp

	class ImagesView < BaseView

		def render
			size = @options[:parent_col_span] || 1
			width = (60 * size) + (20 * (size - 1))
			ubb = ''
			@options[:fileids] ||= ''
			images = @options[:fileids].split(',')
			if images.count > 1
				ubb = '[slideshow]'
				images.each { |id| ubb += "_api__/files/#{id}/download?size=#{width}&type=width\n" }
				ubb += '[/slideshow]'
			else
				ubb += "[img]__api__/files/#{id}/download?size=#{width}&type=width[/img]"
			end
			return WebApp.parse_text(ubb)
		end

		WebApp.register_view('images', ImagesView)

	end


end