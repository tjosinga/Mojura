require 'api/lib/restresource'
require 'api/lib/restresource_tags'
require 'api/resources/polls/polls.objects'
require 'api/resources/polls/votes.rest'

module MojuraAPI

	class PollsResource < RestResource

		def name
			'Polls'
		end

		def description
			'Resource of polls'
		end

		def all(params)
			params[:pagesize] ||= 50
			result = paginate(params) { | options | Polls.new(self.filter(params), options) }
			return result
		end

		def put(params)
			Poll.new.load_from_hash(params).save_to_db.to_a(false, params[:include_votes])
		end

		def get(params)
			Poll.new(params[:ids][0]).to_a(false, params[:include_votes])
		end

		def post(params)
			poll = Poll.new(params[:ids][0])
			poll.load_from_hash(params)
			poll.clear_votes if params[:clear_votes]
			return poll.save_to_db.to_a(false, params[:include_votes])
		end

		def delete(params)
			poll = Poll.new(params[:ids][0])
			poll.delete_from_db
			return [:success => true]
		end

		def all_conditions
			result = {
				description: 'Returns a list of polls. Use pagination to make selections.',
				attributes: {}
			}
			return result
		end

		def put_conditions
			result = {
				description: 'Creates a poll and returns the object.',
				attributes: {
					title: {required: true, type: String, description: 'The title of the poll.'},
					description: {required: false, type: String, description: 'The description of the poll.'},
					options: {required: true, type: String, description: 'All available options for the poll, seperated by newlines \n.'},
					active: {required: false, type: Boolean, description: 'Set to true to make the poll voteable.'},
				}
			}
			result[:attributes].merge(self.tags_conditions)
			return result
		end

		def get_conditions
			{
				description: 'Returns a poll with the specified pollid.',
			}
		end

		def post_conditions
			result =
				{
					description: 'Updates a poll with the given keys.',
					attributes: self.put_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the poll.'
			}
		end

	end

	API.register_resource(PollsResource.new('polls', '', '[pollid]'))
	API.register_resource(TagsResource.new('polls', '[pollid]/tags', '[pollid]/tags', Poll))

end