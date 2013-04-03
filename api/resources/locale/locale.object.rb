require 'kvparser'

module MojuraAPI

	module Locale
		extend self

		private

		@strings = {}

		public

		def load_strings(locale = nil)
			locale ||= API.locale
			locale = locale.to_sym
			if !@strings.include?(locale)
				@strings[locale] = {}
				API.modules.each { | mod_name |
					filename = "api/resources/#{mod_name}/strings.#{locale}.kv"
					@strings[locale][mod_name] = KeyValueParser.parse(File.binread(filename)) if File.exists?(filename)
				}
			end
		end

		public

		def all
			@strings
		end



	end

end
