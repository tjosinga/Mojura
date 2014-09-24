require 'api/lib/restresource'
require 'api/lib/restresource_tags'
require 'api/resources/posts/posts.objects'
require 'api/resources/posts/replies.rest'
require 'api/resources/posts/likes.rest'

module MojuraAPI

	class PostResource < RestResource

		def name
			'Posts'
		end

		def description
			'Resource of posts'
		end

		def all(params)
			#TODO: check rights
			params[:pagesize] ||= 10
			result = paginate(params) { |options| Posts.new(self.filter(params), options) }
			result[:items].each { | post |
				post[:replies] = Replies.new({postid: BSON::ObjectId(post[:id])}).to_a
			} if (params[:include_replies].to_s == 'true')
			return result
		end

		def post(params)
			#TODO: check rights
			Post.new.load_from_hash(params).save_to_db.to_h
		end

		def get(params)
			#TODO: check rights
			Post.new(params[:ids][0]).to_h
		end

		def put(params)
			#TODO: check rights
			post = Post.new(params[:ids][0])
			post.load_from_hash(params)
			return post.save_to_db.to_h
		end

		def delete(params)
			#TODO: check rights
			post = Post.new(params[:ids][0])
			post.delete_from_db
			return [:success => true]
		end

		def all_conditions
			result = {
				description: 'Returns a list of posts. Use pagination and filtering to make selections.',
				attributes: {
					include_replies: {required: false, type: Boolean, description: 'Set true to include the replies as well.'},
				}
			}
			result[:attributes].merge(self.filter_conditions)
			return result
		end

		def post_conditions
			result = {
				description: 'Creates a post and returns the object.',
				attributes: {
					message: {required: true, type: RichText, description: 'The content of the message in the format.'},
				}
			}
			result[:attributes].merge(self.rights_conditions)
			result[:attributes].merge(self.tags_conditions)
			return result
		end

		def get_conditions
			{
				description: 'Returns a post with the specified newsid',
			}
		end

		def put_conditions
			result =
				{
					description: 'Updates a post with the given keys.',
					attributes: self.post_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the posts'
			}
		end

	end

	API.register_resource(PostResource.new('posts', '', '[postid]'))
	API.register_resource(TagsResource.new('posts', '[postid]/tags', Post))

end