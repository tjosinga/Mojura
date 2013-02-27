require 'securerandom'

#noinspection RubyUnusedLocalVariable
module UBBParser

	def self.render_carousel(inner_text, attributes = {}, parse_options = {})
		id = 'ubb-carousel-' + SecureRandom.hex(16)
		width = attributes[:width].to_i
		width = (width > 0) ? width.to_s + 'px' : '100%'
		height = attributes[:height].to_i
		height = (height > 0) ? height.to_s + 'px' : '400px'

		attributes[:style] = "width: #{width}; height: #{height}"
		attrib_str = self.hash_to_attrib_str(attributes, :allowed_keys => [:style])

		result = "<div id='#{id}' class='carousel slide'#{attrib_str}>"
		result += '<div class=\'carousel-inner\'>'
		items = inner_text.split(/\n/)
		active = ' active'
		items.each { |v|
			result += "<div class='item#{active}'>" + self.parse(v, parse_options) + '</div>' if (!v.empty?)
			active = ''
		}
		result += '</div>'
		attributes[:shownav] ||= 'false'
		if attributes[:shownav] == 'true'
			result += "<a class='carousel-control left' href='##{id}' data-slide='prev'>&lsaquo;</a>"
			result += "<a class='carousel-control right' href='##{id}' data-slide='next'>&rsaquo;</a>"
		end
		result += '</div>'
		result += "<script type='text/javascript'>$('##{id}').carousel()</script>"
		return result
	end

	## Not yet implemented
	## :category: Render methods
	#def self.render_googlemaps(inner_text, attributes = {}, parse_options = {})
	#end
	#
	## Not yet implemented
	## :category: Render methods
	#def self.render_googlecalendar(inner_text, attributes = {}, parse_options = {})
	#end
	#
	#def self.render_img_large(inner_text, attributes = {}, parse_options = {})
	#end
	#
	#def self.render_img_left_large(inner_text, attributes = {}, parse_options = {})
	#end
	#
	#def self.render_img_right_large(inner_text, attributes = {}, parse_options = {})
	#end

	# :category: Render methods
	def self.render_quote(inner_text, attributes = {}, parse_options = {})
		source = attributes[:original_attrib_str] || ''
		result = '<blockquote>'
		result += '<p>' + self.parse(inner_text, parse_options) + '</p>'
		result += "<small>#{source}</small>" if !source.empty?
		result += '</blockquote>'
		return result
	end

	# :category: Render methods
	def self.render_readmore(inner_text, attributes = {}, parse_options = {})
		"<span class='readmore'>#{self.parse(inner_text, parse_options)}</span>"
	end

	# Renders the inner_text in a <div> block with inline CSS styles, i.e.:
	def self.render_slideshow(inner_text, attributes = {}, parse_options = {})
		result = '<div class=\'carousel slide\'><div class=\'carousel-inner\'>'
		images = inner_text.split(/\n/)
		images.each { |line|
			result += '<div class=\'item\'><img src=\'line\' alt=\'\' /></div>'
		}
		result += '</div></div>'
		return result
	end

	## :category: Render methods
	#def self.render_swf(inner_text, attributes = {}, parse_options = {})
	#end


end