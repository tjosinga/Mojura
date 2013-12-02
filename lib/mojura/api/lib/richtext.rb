require 'kramdown'
require 'cgi'
require 'ubbparser'
require 'api/lib/ubbparser_additions'

module MojuraAPI

	# The RichText datatype is a string formatted in a specific markup. It currently supports:
	# - Plain text
	# - UBB code
	# - Markdown
	# - HTML
	# This class also supports the
	class RichText < String

		attr_accessor :markup

		def initialize(str = '', markup = :ubb)
			@markup = markup.to_sym rescue :ubb
			super(str.to_s)
		end

		def to_html
			result = case @markup
				         when :ubb then
					         UBBParser.parse(self)
				         when :markdown then
					         Kramdown::Document.new(self).to_html
				         when :html then
					         self
				         else
					         CGI.escapeHTML(self)
			         end
			return result
		end

		def to_parsed_a(compact = false)
			result = {}
			if compact
				str, idle = self.to_s.split('[readmore]', 2)
				str = str.to_s.rstrip
				idle = idle.to_s.lstrip
			else
				str = self.to_s
				idle = ''
			end
			result[:raw] = str.to_s
			result[:markup] = @markup
			result[:html] = RichText.new(result[:raw]).to_html
 			result[:readmore] = !idle.empty?
			return result
		end

	end

end
