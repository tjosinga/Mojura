module MojuraAPI

	class ValidationError < Exception
		attr :invalid_validations
		attr :invalid_value

		def initialize(invalid_validations, invalid_key, invalid_value)
			@invalid_validations = invalid_validations.to_s
			@invalid_value = invalid_value
			super("The validation(s) of #{invalid_key} failed on the value '#{invalid_value}': #{invalid_validations}")
		end

	end

	module Validator

		def self.matches_regexp?(value, regexp)
			return !value.to_s.match(regexp).nil?
		end

		def self.is_required?(value)
			if value.is_a?(String)
				result = (value != '')
			else
				result = !value.nil?
			end
			return result
		end

		def self.is_numeric?(value)
			return false if !value.respond_to?('to_s')
			return false if !value.respond_to?('to_i')
			return (value.to_s == value.to_i.to_s)
		end

		def self.is_email?(value)
			return false if !value.is_a?(String)
			return self.matches_regexp?(value, /^([a-zA-Z0-9_\-\.\+]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/)
		end

		def self.is_url?(value)
			return self.matches_regexp?(value, /^(http|https):\/\/([a-zA-Z0-9\.\-]+(:[a-zA-Z0-9\.&amp;%\$\-]+)*@)*((25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9])|localhost|([a-zA-Z0-9\-]+\.)*[a-zA-Z0-9\-]+\.(com|edu|gov|int|mil|net|org|biz|arpa|info|name|pro|aero|coop|museum|[a-zA-Z]{2}))(:[0-9]+)*(\/($|[a-zA-Z0-9\.,\?'\\\+&amp;%\$#=~_\-]+))*$/)
		end

		def self.in_array?(value, arr)
			return (arr.to_a || []).include?(value)
		end

		def self.not_in_array?(value, arr)
			return !self.in_array(value, arr)
		end

	end
end