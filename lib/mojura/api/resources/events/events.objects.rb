require 'digest'
require 'api/lib/dbobjects'
require 'api/resources/groups/groups.objects'

module MojuraAPI

	class Event < DbObject

		include DbObjectTags
		include DbObjectRights

		def initialize(id = nil)
			super('events', id)
		end

		def load_fields
			yield :title, String, :required => true
			yield :location, String, :required => false
			yield :category, String, :required => false, :validations => {matches_regexp: /^[a-zA-Z]+[\w\.-]*$/}
			yield :start_date, Date, :required => true, :default => Date.new
			yield :start_time, Date, :required => false
			yield :end_date, Date, :required => false
			yield :end_time, Date, :required => false
			#yield :recurring, Boolean, :required, :default => false
			yield :notes, RichText, :required => false
		end

	end


	class Events < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {start: -1}
			super('events', NewsItem, where, options)
		end

	end


end



