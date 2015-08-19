require 'kvparser'

module MojuraWebApp

	module Locale
		extend self

		private

		@strings = {}

		public

		def load_strings(view, locale = nil)
			locale ||= WebApp.locale
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
				strings_file = Mojura.filename(strings_file)
				unless strings_file.empty?
					@strings[locale][view] = KeyValueParser.parse(File.read(strings_file))
					@strings[locale][view].symbolize_keys!
				end
			rescue Exception => e
				raise CorruptStringsFileException.new(view, e.to_s)
			end
		end

		public

		def strings(view, options = {})
			locale = options[:locale] || WebApp.locale
			view = view.to_sym
			@strings[locale] ||= {}
			self.load_strings(view) unless (@strings[locale].include?(view))
			result = @strings[locale][view]
			if result.nil?
				fallback = Settings.get_s(:fallback_locale, :core, :en).to_sym
				result = @strings[fallback][view] rescue nil
			end
			return result || {}
		end

		def str(view, id, options = {})
			locale = options[:locale].to_sym rescue WebApp.locale
			view = view.to_sym
			@strings[locale] ||= {}
			self.load_strings(view) unless (@strings[locale].include?(view))
			@strings[locale][view] ||= {}

			result = @strings[locale][view][id.to_sym]
			if result.nil?
				fallback = Settings.get_s(:fallback_locale, :core, :en).to_sym
				load_strings(view, fallback) unless @strings.include?(fallback) && @strings[fallback].include?(view)
				result = '[' + @strings[fallback][view][id.to_sym] + ']' rescue nil
			end
			return (result || options[:default] || "__#{view}_#{id}__")
		end
	end

end
