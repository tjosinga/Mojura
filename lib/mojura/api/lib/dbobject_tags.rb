module MojuraAPI

	# DbObjectTags is a mixin module for DbObject and adds tag support for an object.
	# :category: DbObject
	module DbObjectTags

		def load_tags_fields
			yield :tags, Array, :required => true, :default => []
		end

		def add_tags(tags)
			tags.map! { |tag| tag.strip }
			tags.delete('')
			tags.each { |tag| @fields[:tags][:value].push(tag) }
			@fields[:tags][:value].uniq!
			@fields[:tags][:value].sort!
			@fields[:tags][:changed] = true
		end

		def delete_tags(tags)
			tags.map! { |tag| tag.strip }
			tags.delete('')
			tags.each { |tag| @fields[:tags][:value].delete(tag) }
			@fields[:tags][:changed] = true
		end

	end

end