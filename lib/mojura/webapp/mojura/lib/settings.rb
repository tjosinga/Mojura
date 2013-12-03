module MojuraWebApp

	module Settings
		extend self

		def all(scopes = [:protected, :public], include_level = true)
			scopes
			return MojuraAPI::Settings.all(scopes, include_level)
		end

		def get_s(key, category = :core, default = nil, scopes = [:protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_s(key, category, default, scopes)
		end

		def get_i(key, category = :core, default = nil, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_i(key, category, default, scopes)
		end

		def get_f(key, category = :core, default = nil, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_f(key, category, default, scopes)
		end

		def get_b(key, category = :core, default = nil, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_b(key, category, default, scopes)
		end

		def get_h(key, category = :core, default = nil, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_h(key, category, default, scopes)
		end

		def get_a(key, category = :core, default = nil, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_a(key, category, default, scopes)
		end

		def set(key, value, category = :core, is_public = false)
			level = (is_public) ? :public : :protected
			return MojuraAPI::Settings.set(key, value, category, level)
		end

	end

end