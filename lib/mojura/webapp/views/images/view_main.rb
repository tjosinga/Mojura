require 'ubbparser'

module MojuraWebApp

	class ImagesView < BaseView

		def render
			size = @options[:parent_col_span] || 1
			ubb = ''
			@options[:fileids] ||= ''
			@options[:slideshow] ||= false
			images = @options[:fileids].split(',')
			if (images.count > 1) && (@options[:slideshow])
				ubb = "[slideshow]"
				images.each { |id| ubb += "__api__/files/#{id}/download\n" }
				ubb += '[/slideshow]'
			elsif images.count > 0
				images.each { |id| ubb += "[img]__api__/files/#{id}/download[/img]" }
			else
				ubb = 'No image id specified ' + images.to_s
			end
			return WebApp.parse_text(ubb)
		end

		WebApp.register_view('images', ImagesView)

	end


end