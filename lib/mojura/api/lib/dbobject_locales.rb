module MojuraAPI

	# DbObjectTags is a mixin module for DbObject and adds votes support for an object.
	# :category: DbObject
	module DbObjectLocales

		def load_locales_fields
			yield :locales, Array, :required => true, :default => [] if API.multilingual?
		end

	end

end