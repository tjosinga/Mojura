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
			yield :category, String, :required => true, :validations => {matches_regexp: /^[a-zA-Z]+[\w\.-]*$/}
			yield :title, String, :required => true
			yield :imageid, BSON::ObjectId, :required => true, :default => nil
			yield :timestamp, Time, :required => false, :default => Time.new
			yield :content, RichText, :required => true
		end

	end


	class NewsItems < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {timestamp: -1}
			super('news', NewsItem, where, options)
		end

	end


end



