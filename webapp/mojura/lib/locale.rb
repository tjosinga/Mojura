require 'kvparser'

module MojuraWebApp

	module Locale
		extend self

		private

		@strings = {}

		public

		def load_strings(view, locale = nil)
			locale ||= WebApp.page.locale
			view = view.to_sym
			begin
				strings_file = case view
					               when :system then
						               "webapp/mojura/views/strings.#{locale}.kv"
					               when :view_template_names then
						               "webapp/mojura/views/strings_view_template_names.#{locale}.kv"
					               else
						               "webapp/views/#{view}/strings.#{locale}.kv"
				               end
				@strings[locale] ||= {}
				if File.exists?(strings_file)
					@strings[locale][view] = KeyValueParser.parse(File.read(strings_file))
					@strings[locale][view].symbolize_keys!
				end
			rescue Exception => e
				raise CorruptStringsFileException.new(view, e.to_s)
			end
		end

		public

		def all
			@strings
		end

		def str(view, id, options = {})
			locale = options[:locale] || WebApp.page.locale
			view = view.to_sym
			@strings[locale] ||= {}
			self.load_strings(view) unless (@strings[locale].include?(view))
			@strings[locale][view] ||= {}
			return (@strings[locale][view][id.to_sym] || options[:default] || "__#{view}_#{id}__")
		end
	end

end
