require 'api/lib/settings'

module MojuraWebApp

	module Settings
		extend self

		def all(scopes = [:protected, :public], include_level = true)
			scopes.delete(:private)
			return MojuraAPI::Settings.all(scopes, include_level)
		end

		def get(key, default = nil, category = :core, scopes = [:protected, :public])
			scopes.delete(:private)
			return MojuraAPI::Settings.get(key, default, category, core, scopes)
		end

		def set(key, value, category = :core, is_public = false)
			level = (is_public) ? :public : :protected
			return MojuraAPI::Settings.set(key, value, category, level)
		end

	end

end