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
				API.modules.each { |mod_name|
					filename = Mojura.filename("api/resources/#{mod_name}/strings.#{locale}.kv")
					@strings[locale][mod_name] = KeyValueParser.parse(File.binread(filename)) unless filename.empty?
				}
			end
		end

		public

		def strings(view, options = {})
			locale = options[:locale] || API.locale
			view = view.to_sym
			@strings[locale] ||= {}
			self.load_strings(view) unless (@strings[locale].include?(view))
			@strings[locale][view] ||= {}
			return (@strings[locale][view] || {})
		end

		def all(options = {})
			locale = options[:locale] || API.locale
			return @strings[locale]
		end

		def str(view, id, options = {})
			locale = options[:locale] || API.locale
			view = view.to_sym
			@strings[locale] ||= {}
			self.load_strings(view) unless (@strings[locale].include?(view))
			@strings[locale][view] ||= {}
			return (@strings[locale][view][id.to_sym] || options[:default] || "__#{view}_#{id}__")
		end
	end

end