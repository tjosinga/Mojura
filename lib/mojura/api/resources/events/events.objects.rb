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
			yield :start, Time, :required => true, :default => Time.new
			yield :duration, Integer, :default => 60
			yield :all_day, Boolean, :default => false
			#yield :recurring, Boolean, :required, :default => false
			yield :notes, RichText, :required => false
		end

	end


	class Events < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {start: -1}
			super('events', Event, where, options)
		end

	end


end



