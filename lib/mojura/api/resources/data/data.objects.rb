require 'api/lib/dbobjects'
require 'api/resources/groups/groups.objects'

module MojuraAPI

	class DataBlock < DbObject

		def initialize(id = nil)
			super('data', id)
		end

		def load_fields
			yield :type, String, :required => true
			yield :name, String, :required => true
			yield :email, String, :required => true, :validations => {is_email: true}
			yield :timestamp, DateTime, :required => true, :default => Time.new.iso8601
			yield :text, RichText, :required => false
			yield :values, Hash, :required => false, :default => {}
		end

	end


	class DataBlocks < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {timestamp: -1}
			super('data', DataBlock, where, options)
		end

	end


end



