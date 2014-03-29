require 'api/lib/dbobjects'

module MojuraAPI

	class Poll < DbObject

		def initialize(id = nil, options = {})
			super('polls', id)
		end

		def load_fields
			yield :title, String, :required => true, :searchable => true, :searchable_weight => 3
			yield :description, String, :searchable => true
			yield :options, Array, :default => []
			yield :active, Boolean, :default => false
			yield :votes, Array, :default => [], :hidden => true
			yield :blocked_ips, Hash, :default => {}, :hidden => true
		end

		def voteable(ip = nil)
			ip = API.remote_ip if ip.nil?
			block_expiration = Settings.get_i(:block_duration, :polls, 86400)
			blocked_ips.delete_if { | _, timestamp | timestamp < (Time.now.to_i - block_expiration) }
			return active && !blocked_ips.include?(ip.gsub('.', "\uFF0E"))
		end

		def vote(index, ip = nil)
			ip = API.remote_ip if ip.nil?
			return false unless voteable(ip)
			return false unless (index < options.size)
			votes[index] ||= 0
			votes[index] += 1
			@fields[:votes][:changed] = true
			blocked_ips[ip.gsub('.', "\uFF0E")] = Time.now.to_i
			@fields[:blocked_ips][:changed] = true
			API.log.info(JSON.pretty_generate(votes))
			save_to_db
			return true
		end

		def get_votes(include_votes = true)
			result = {}
			result[:options] = []
			result[:total_votes] = votes.inject { | sum, i | sum + i }
			f = 100.00 / result[:total_votes] rescue 0.00
			options.each_index { | index |
				url = API.api_url + "polls/#{self.id}/votes/?_method=put&index=#{index}"
				option = {title: options[index], index: index, vote_url: url}
				a = votes[index] || 0
				option[:votes] = { absolute: a, percentage: f * a } if include_votes
				result[:options].push(option)
			}
			return result
		end

		def clear_votes
			votes = []
		end

		def to_a(compact = false, include_votes = false, ip = nil)
			result = super(compact)
			result.merge!(get_votes(include_votes))
			result[:voteable] = voteable
			return result
		end

	end

	class Polls < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {_id: -1}
			super('polls', Poll, where, options)
		end

	end



end



