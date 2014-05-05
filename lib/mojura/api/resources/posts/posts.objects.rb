require 'digest'
require 'api/lib/dbobjects'

module MojuraAPI

	class PostsMessage < DbObject

		include DbObjectTags
		include DbObjectRights

		def initialize(type, id = nil, options = {})
			type = (type == 'posts') ? 'posts' : 'replies'
			super("posts_#{type}", id)
		end

		def load_fields
			yield :message, RichText, :required => true, :searchable => true
			yield :author, BSON::ObjectId, :required => true, :default => API.current_user.id
			yield :likes, Hash, :default => {}
			yield :mentions, Array, :default => []
			yield :urls, Array, :default => {}
			yield :timestamp, Time, :required => true, :default => Time.new
		end

		def like
			unless (likes.include?(API.current_user.id))
				@fields[:likes][:changed] = true
				likes[API.current_user.id] = API.current_user.fullname
				save_to_db
			end
		end

		def unlike
			if (likes.include?(API.current_user.id))
				@fields[:likes][:changed] = true
				likes.delete(API.current_user.id)
				save_to_db
			end
		end

		def on_save_data(data)
			if data.include?(:message)
				data.merge!(process_message)
			end
			return data
		end

		def to_a(compact = false)
			result = super
			result[:author] = User.new(result[:author]).to_a
			result[:you_like_this] = result[:likes].include?(API.current_user.id)
			return result
		end

		# Sets all changed fields and returns a hash with them too.
		def process_message
			@fields[:tags][:changed] = true;
			@fields[:tags][:value] = []
			message.scan(/(#(\w{2,}))/) { | m |
				@fields[:tags][:value].push(m[1])
			}

			@fields[:mentions][:changed] = true;
			@fields[:mentions][:value] = []
			message.scan(/(@(\w{2,}))/) { | m |
				@fields[:mentions][:value].push(m[1])
			}

			STDOUT << {
				tags: @fields[:tags][:value],
				mentions: @fields[:mentions][:value]
			}.to_s + "\n"

			#TODO: detect urls
			return {
				tags: @fields[:tags][:value],
				mentions: @fields[:mentions][:value]
			}
		end

		def extract_hashtags

		end

	end

	class Post < PostsMessage

		include DbObjectRights

		def initialize(id = nil)
			super('posts', id)
		end

		def load_fields
			yield :title, String, :required => false
			super
			yield :praises, Hash, :default => {}
		end

		def api_url
			API.api_url + "posts/#{id}"
		end

		def to_a(compact = false)
			result = super
			result[:replies_url] = API.api_url + "posts/#{id}/replies"
			return result
		end

	end


	class Posts < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {timestamp: -1}
			super('posts_posts', Post, where, options)
		end

	end


	class Reply < PostsMessage

		def initialize(id = nil)
			super('replies', id)
		end

		def load_fields
			yield :postid, BSON::ObjectId, :required => true
			super
		end

		def api_url
			API.api_url + "posts/#{postid}/reply/#{id}"
		end

	end


	class Replies < DbObjects

		def initialize(where = {}, options = {})
			super('posts_replies', Reply, where, options)
		end

	end


end



