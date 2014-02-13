require 'ubbparser'

def ubbparser_convert_file_url(url)
	STDOUT << "Converting #{url}\n"
	url.gsub!(/\A([0-9a-f]{24})\z/, MojuraAPI::API.api_url + "files/\\1/download")
	STDOUT << "to #{url}\n"
	return url
end

#noinspection RubyUnusedLocalVariable
module UBBParser

	self.set_file_url_convert_method(method(:ubbparser_convert_file_url))

	def self.render_carousel(inner_text, attributes = {}, parse_options = {})
		id = 'ubb-carousel-' + SecureRandom.hex(16)
		width = attributes[:width].to_i
		width = (width > 0) ? width.to_s + 'px' : '100%'

		attributes[:style] = "width: #{width}"
		attrib_str = self.hash_to_attrib_str(attributes, :allowed_keys => [:style])

		result = "<div id='#{id}' class='carousel ubb-carousel slide' #{attrib_str}>"
		result += "<div class='carousel-inner'>"
		items = inner_text.split(/\n/)
		active = ' active'
		items.each { |v|
			if !v.empty?
				result += "<div class='item#{active}'>" + self.parse(v, parse_options) + '</div>'
				active = ''
			end
		}
		result += '</div>'
		attributes[:shownav] ||= 'false'
		if attributes[:shownav] == 'true'
			result += "<a class='carousel-control left' href='##{id}' data-slide='prev'>&lsaquo;</a>"
			result += "<a class='carousel-control right' href='##{id}' data-slide='next'>&rsaquo;</a>"
		end
		result += '</div>'
		result += "<script type='text/javascript'>$('##{id}').carousel('cycle')</script>"
		return result
	end

	# :category: Render methods
	def self.render_icon(inner_text, attributes = {}, parse_options = {})
		icon_type = (inner_text.match(/^[\w\-]*$/).nil?) ? 'question' : inner_text
		return "<span class='fa fa-#{icon_type}'></span>"
	end

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
		"<span class='readmore'>#{self.parse(inner_text.lstrip, parse_options)}</span>"
	end

	# Renders the inner_text in a <div> block with inline CSS styles, i.e.:
	def self.render_slideshow(inner_text, attributes = {}, parse_options = {})
		id = 'ubb-carousel-' + SecureRandom.hex(16)
		result = "<div id='#{id}' class='carousel slide'><div class='carousel-inner'>"
		active = ' active'
		images = inner_text.split(/\n/)
		images.each { |line|
			result += "<div class='item#{active}'><img src='#{line}' alt='' /></div>"
			active = ''
		}
		result += '</div></div>'
		result += "<script type='text/javascript'>$('##{id}').carousel('cycle')</script>"
		return result
	end

	## :category: Render methods
	#def self.render_swf(inner_text, attributes = {}, parse_options = {})
	#end

end