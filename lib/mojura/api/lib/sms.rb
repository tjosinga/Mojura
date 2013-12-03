require 'net/http'
require 'uri'
require 'api/lib/settings'

module MojuraAPI

	module SMS
		extend self

		def send(dest, message, options = {})
			# dest should be a string, or an array of strings containing mobile phone numbers
			options[:skip_invalid_dests] ||= true
			options[:test] = Settings.get_b(:testing, :sms)

			dest = [dest] if dest.is_a?(String)
			# check whether dest is valid

			service = 'MessageBird' #Settings.get_s(:service, :sms)
			count_succeeded = case service
				when 'MessageBird' then self.send_via_messagebird(dest, message, options)
				else -1
				# insert new services here and create corresponding method below
			end
			return count_succeeded
		end

		def send_via_messagebird(dest, message, options)
			username = Settings.get_s(:api_username, :sms)
			password = Settings.get_s(:password, :sms)
			sender = Settings.get_s(:sender, :sms)

			if (username.empty?) || (password.empty?) || (sender.empty?)
				raise SMSInvalidConfiguration.new('MessageBird')
			end

			api_url = 'http://api.messagebird.com/api/sms'
			body = URI.escape(message)
			destinations = dest.join(",")
			request_url = "#{api_url}?username=#{username}&password=#{password}&body=#{body}&"
			request_url += "sender=#{sender}&destination=#{destinations}"
			request_url += "&test=1" if options[:test]

			url = URI.parse(request_url)
			full_path = (url.query.empty?) ? url.path : "#{url.path}?#{url.query}"
			request = Net::HTTP::Get.new(full_path)
			Net::HTTP.start(url.host, url.port) { | http | http.request(request) }
			return dest.size
		end

	end

end