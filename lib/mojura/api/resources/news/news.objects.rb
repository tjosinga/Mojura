require 'digest'
require 'api/lib/dbobjects'
require 'api/resources/groups/groups.objects'

module MojuraAPI

	class NewsItem < DbObject

		include DbObjectTags
		include DbObjectVotes
		include DbObjectRights

		def initialize(id = nil)
			super('news', id)
		end

		def load_fields
			yield :title, String, :required => true, :searchable => true, :searchable_weight => 3
			yield :category, String, :required => false, :validations => {matches_regexp: /^[a-zA-Z]+[\w\.-]*$/}
			yield :imageid, BSON::ObjectId, :required => false, :default => nil
			yield :timestamp, Time, :required => false, :default => Time.new
			yield :content, RichText, :required => true, :searchable => true
		end

	end


	class NewsItems < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {timestamp: -1}
			super('news', NewsItem, where, options)
		end

	end


end



