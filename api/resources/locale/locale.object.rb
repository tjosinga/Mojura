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
					filename = "api/resources/#{mod_name}/strings.#{locale}.yaml"
					if File.exists?(filename)
						@strings[locale][mod_name] = YAML.load_file(filename)
						@strings[locale][mod_name].symbolize_keys!
					end
				}
			end
		end

		public

		def all
			@strings
		end

		def str(mod_name, key, locale = nil, return_empty = false)
			locale ||= API.locale
			locale = locale.to_sym
			mod_name = mod_name.to_sym
			key = key.to_sym
			self.load_strings(locale) unless (@strings.include?(locale))
			if @strings[locale].include?(mod_name) && @strings[mod_name].include?(key)
				result = @strings[mod_name][key]
			elsif return_empty
				result = ''
			else
				self.load(:en) unless (@strings.include?(:en))
				result = @strings[:en][mod_name][key] rescue nil
				result = "__#{mod_name}_#{key}__" if result.nil?
			end
			return result
		end

	end

end
