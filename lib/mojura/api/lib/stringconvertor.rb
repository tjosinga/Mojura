require 'date'
require 'api/lib/datatypes'

module MojuraAPI

	class StringConvertor

		# Array, Float, Hash, Integer, Boolean, Date, DateTime, Set

		def self.convert(value, type)
			return value if (type == String) || (type == 'String') || (value.nil?) || (!value.is_a?(String))
			case type.to_s.downcase
				when 'array' then
					return value.split("\n")
				when 'float' then
					return value.to_f rescue 0
				when 'hash' then
					return JSON.parse(value) rescue {}
				when 'integer' then
					return value.to_i rescue 0
				when 'boolean' then
					return (value.downcase == 'true')
				when 'trueclass' then
					return (value.downcase == 'true')
				when 'falseclass' then
					return (value.downcase == 'true')
				when 'date' then
					return Date.parse(value).strftime('%F') rescue Date.today.strftime('%F')
				when 'datetime' then
					return Time.parse(value).strftime('%FT%T') rescue Time.now.strftime('%FT%T')
				when 'time' then
					return Time.parse(value).strftime('%T') rescue Time.now.strftime('%T')
				when 'richtext' then
					return RichText.new(value)
				when 'bson::objectid' then
					return BSON::ObjectId(value) rescue nil
				else
					return value
			end
		end

	end

end