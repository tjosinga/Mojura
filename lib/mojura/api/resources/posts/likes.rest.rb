require 'api/lib/restresource'
require 'api/resources/posts/posts.objects'

module MojuraAPI

	class LikesResource < RestResource

		def name
			'Likes'
		end

		def description
			'Resource of post message, wether it is a post or a reply'
		end

		def all(params)
			#TODO: check rights
			message = (params[:ids].size == 2) ? Reply.new(params[:ids][1]) : Post.new(params[:ids][0])
			return message.likes
		end

		def put(params)
			#TODO: check rights
			message = (params[:ids].size == 2) ? Reply.new(params[:ids][1]) : Post.new(params[:ids][0])
			message.like
			return message.likes
		end

		def delete(params)
			#TODO: check rights
			message = (params[:ids].size == 2) ? Reply.new(params[:ids][1]) : Post.new(params[:ids][0])
			message.unlike
			return message.likes
		end

		def all_conditions
			result = {
				description: 'Returns all likes of a message, wether it\'s post or a reply.',
				attributes: {}
			}
			return result
		end

		def put_conditions
			{
				description: 'Likes a message',
			}
		end

		def delete_conditions
			{
				description: 'Unlikes a message'
			}
		end

	end

	API.register_resource(LikesResource.new('posts', '[postid]/likes', '[postid]/likes'))
	API.register_resource(LikesResource.new('posts', '[postid]/reply/[replyid]/likes', '[postid]/reply/[replyid]/likes'))

end