module MojuraWebApp

	module Settings
		extend self

		def all(scopes = [:protected, :public], include_level = true)
			scopes
			return MojuraAPI::Settings.all(scopes, include_level)
		end

		def get_s(key, category = :core, scopes = [:protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_s(key, category, scopes)
		end

		def get_i(key, category = :core, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_i(key, category, scopes)
		end

		def get_f(key, category = :core, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_f(key, category, scopes)
		end

		def get_b(key, category = :core, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_b(key, category, scopes)
		end

		def get_h(key, category = :core, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_h(key, category, scopes)
		end

		def get_a(key, category = :core, scopes = [:private, :protected, :public])
			scopes.delete(:private)
			MojuraAPI::Settings.get_a(key, category, scopes)
		end

		def set(key, value, category = :core, is_public = false)
			level = (is_public) ? :public : :protected
			return MojuraAPI::Settings.set(key, value, category, level)
		end

	end

end