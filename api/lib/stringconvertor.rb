require 'date'
require 'api/lib/datatypes'

module MojuraAPI

	class StringConvertor

		# Array, Float, Hash, Integer, Boolean, Date, DateTime, Set

		def self.convert(value, type)
			return value if (type == String) || (type == 'String') || (value.nil?) || (!value.is_a?(String))
			return case type.to_s.downcase
				       when 'array' then
					       value.split("\n")
				       when 'float' then
					       value.to_f rescue 0
				       when 'hash' then
					       JSON.parse(value) rescue {}
				       when 'integer' then
					       value.to_i rescue 0
				       when 'boolean' then
					       (value.downcase == 'true')
				       when 'date' then
					       Date.parse(value) rescue Date.today
				       when 'datetime' then
					       DateTime.parse(value) rescue DateTime.now
				       when 'richtext' then
					       RichText.new(value)
				       when 'bson::objectid' then
					       BSON::ObjectId(value) rescue nil
				       else
					       value
			       end
		end

	end

end