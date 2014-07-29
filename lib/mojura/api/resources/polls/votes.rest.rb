require 'api/lib/restresource'
require 'api/resources/polls/polls.objects'

module MojuraAPI

	class PollVotesResource < RestResource

		def name
			'Polls'
		end

		def description
			'Resource of polls'
		end

		def all(params)
			Poll.new(params[:ids][0]).get_votes
		end

		def post(params)
			index = params[:index] || -1
			poll = Poll.new(params[:ids][0])
			if poll.vote(index.to_i, API.remote_ip)
				return poll.to_a(false, params[:include_votes])
			else
				return { error: 'Unable to vote. Probably you need to wait 24 hours.' }
			end
		end

		def all_conditions
			result = {
				description: 'Returns the voting results of the poll.',
				attributes: {}
			}
			return result
		end

		def post_conditions
			result = {
				description: 'Votes on an option of a poll.',
				attributes: {}
			}
			return result
		end

	end

	API.register_resource(PollVotesResource.new('polls', '[pollid]/votes'))

end