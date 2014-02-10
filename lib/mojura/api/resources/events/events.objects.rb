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
			yield :end, Time, :hidden => true # only for querying confenience
			yield :all_day, Boolean, :default => false
			#yield :recurring, Boolean, :required, :default => false
			yield :notes, RichText, :required => false
		end

		def on_save_data(data)
			if data.include?(:start) || data.include?(:duration)
				data[:end] = start + (duration * 60)
				@fields[:end][:value] = data[:end]
			end
		end

	end


	class Events < DbObjects

		def initialize(start_range, end_range, where = {}, options = {})
			options[:sort] ||= { start: -1 }
			start_range ||= Time.new.utc
			where ||= {}
			where[:end] ||= {'$gte' => start_range}
			where[:start] ||= {'$lte' => end_range} unless end_range.nil? || (end_range < start_range)
			STDOUT << JSON.pretty_generate(where) + "\n"
			super('events', Event, where, options)
		end

	end


end



