require 'api/lib/restresource'
require 'api/lib/restresource_tags'
require 'api/resources/posts/posts.objects'

module MojuraAPI

	class PostIdMismatchException < HTTPException

		def initialize
			super('The postid in the url mismatches the postid in the reply')
		end

	end

	class ReplyResource < RestResource

		def name
			'Replies'
		end

		def description
			'Resource of replies'
		end

		def all(params)
			#TODO: check rights
			postid = params[:ids][0]
			params[:pagesize] ||= 50
			result = paginate(params) { | options | Replies.new({postid: BSON::ObjectId(postid)}, options) }
			return result
		end

		def put(params)
			#TODO: check rights
			params[:postid] = params[:ids][0]
			Reply.new.load_from_hash(params).save_to_db.to_a
		end

		def get(params)
			#TODO: check rights
			reply = Reply.new(params[:ids][1])
			STDOUT << JSON.pretty_generate(reply.to_a)
			raise PostIdMismatchException.new if (params[:ids][0] != reply.postid.to_s)
			return reply.to_a
		end

		def post(params)
			#TODO: check rights
			reply = Reply.new(params[:ids][1])
			raise PostIdMismatchException.new if (params[:ids][0] != reply.postid.to_s)
			reply.load_from_hash(params)
			return reply.save_to_db.to_a
		end

		def delete(params)
			#TODO: check rights
			reply = Reply.new(params[:ids][1])
			raise PostIdMismatchException.new if (params[:ids][0] != reply.postid.to_s)
			reply.delete_from_db
			return [:success => true]
		end

		def all_conditions
			result = {
				description: 'Returns a list of replies.',
				attributes: {
					complete: {required: false, type: Boolean, description: 'If set to true, it will return the complete content of the replies. If set to false (default) it will return only the first part of the message. The read more parameter indicates whether a reply has more to read.'},
				}
			}
			result[:attributes].merge(self.filter_conditions)
			return result
		end

		def put_conditions
			result = {
				description: 'Creates a reply and returns the object.',
				attributes: {
					message: {required: true, type: RichText, description: 'The content of the item in the format.'},
				}
			}
			return result
		end

		def get_conditions
			{
				description: 'Returns a reply with the specified newsid',
			}
		end

		def post_conditions
			result =
				{
					description: 'Updates a reply with the given keys.',
					attributes: self.put_conditions[:attributes]
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the reply.'
			}
		end

	end

	API.register_resource(ReplyResource.new('posts', '[postid]/replies/', '[postid]/reply/[replyid]'))
	API.register_resource(TagsResource.new('posts', '[postid]/reply/[replyid]/tags', Reply))

end