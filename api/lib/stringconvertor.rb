require 'date'
require 'api/lib/datatypes'

module MojuraAPI

  class StringConvertor

  # Array, Float, Hash, Integer, Boolean, Date, DateTime, Set

    def self.convert(value, type)
      return value if (type == String) || (value.nil?) || (!value.is_a?(String))
      return case type.to_s
        when 'Array' then value.split("\n")
        when 'Float' then value.to_f rescue 0
        when 'Hash' then JSON.parse(value) rescue {}
        when 'Integer' then value.to_i rescue 0
        when 'Boolean' then (value.downcase == 'true')
        when 'Date' then Date.parse(value) rescue Date.today
        when 'DateTime' then DateTime.parse(value) rescue DateTime.now
        when 'RichText' then RichText.new(value)
        when 'BSON::ObjectId' then BSON::ObjectId(value) rescue nil
        else value
      end
    end

  end

end