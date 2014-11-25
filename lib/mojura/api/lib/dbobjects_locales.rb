module MojuraAPI

	# DbObjectsLocales is a mixin module for DbObjects and automatically gives it locales support when added.
	# DbObjects will include this module automatically based on the class of a single item
	# :category: DbObject
	module DbObjectsLocales

		def update_where_with_locales(where = {})
			if API.multilingual? && !@options[:ignore_locale]
				locales_where = {'$or' => [
					{'locales' => {'$exists' => false}},
					{'locales' => []},
					{'locales' => API.locale}
				]}
				where = {'$and' => [where, locales_where] }
			end
			return where
		end
	end

end