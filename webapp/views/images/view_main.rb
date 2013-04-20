require 'ubbparser'

module MojuraWebApp

	class ImagesView < BaseView

		def render
			size = @options[:parent_col_span] || 1
			width = (70 * size) + (30 * (size - 1))
			ubb = ''
			@options[:fileids] ||= ''
			@options[:slideshow] ||= false
			images = @options[:fileids].split(',')
			if (images.count > 1) && (@options[:slideshow])
				ubb = "[slideshow width=#{width}]"
				images.each { |id| ubb += "__api__/files/#{id}/download?size=#{width}&type=width\n" }
				ubb += '[/slideshow]'
			elsif images.count == 1
				images.each { |id| ubb += "[img]__api__/files/#{id}/download?size=#{width}&type=width[/img]" }
			else
				ubb = 'No image id specified'
			end
			return WebApp.parse_text(ubb)
		end

		WebApp.register_view('images', ImagesView)

	end


end