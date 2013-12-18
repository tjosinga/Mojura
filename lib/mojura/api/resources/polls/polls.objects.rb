require 'api/lib/dbobjects'

module MojuraAPI

	class Poll < DbObject

		def initialize(type, id = nil, options = {})
			super('polls', id)
		end

		def load_fields
			yield :title, String, required => true
			yield :options, Array, :default => []
			yield :active, Boolean, :default => false
			yield :votes, Array, :default => []
			yield :blocked_ips, Hash, :default => {}, :hidden => true
		end

		def vote(index, ip)
			return false if (@blocked_ips[ip].to_i > (Time.now - 86400))
			return false if index >= @options.size
			@votes[index] ||= 0
			@votes[index] += 1
			@fields[:votes][:changed] = true
			@blocked_ips.delete_if { | ip, timestamp | timestamp < (Time.now - 86400) }
			@blocked_ips[ip] = Time.now
			@fields[:blocked_ips][:changed] = true
			return true
		end

		def clear_votes
			@fields[:votes] = {}
		end

	end

	class Polls < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {timestamp: -1}
			super('polls', Poll, where, options)
		end

	end



end



