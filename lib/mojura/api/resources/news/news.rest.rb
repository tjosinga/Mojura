require 'api/lib/restresource'
require 'api/lib/restresource_tags'
require 'api/resources/news/news.objects'

module MojuraAPI

	class NewsResource < RestResource

		def name
			'News items'
		end

		def description
			'Resource of news items'
		end

		def all(params)
			params[:pagesize] ||= 10
			result = paginate(params) { |options| NewsItems.new(self.filter(params), options) } #self.filter(params), options) }
			                                                                                    #result[:items].each { | item |
			                                                                                    #	item[:content] += "blaat"
			                                                                                    #}
			return result
		end

		def post(params)
			NewsItem.new.load_from_hash(params).save_to_db.to_a
		end

		def get(params)
			NewsItem.new(params[:ids][0]).to_a
		end

		def put(params)
			newsitem = NewsItem.new(params[:ids][0])
			newsitem.load_from_hash(params)
			return newsitem.save_to_db.to_a
		end

		def delete(params)
			newsitem = NewsItem.new(params[:ids][0])
			newsitem.delete_from_db
			return [:success => true]
		end

		def all_conditions
			result = {
				description: 'Returns a list of news items. Use pagination and filtering to make selections.',
				attributes: {
					complete: {required: false, type: Boolean, description: 'If set to true, it will return the complete content of the news items. If set to false (default) it will return only the first part of the message. The read more parameter indicates whether a news item has more to read.'},
				}
			}
			result[:attributes].merge(self.filter_conditions)
			return result
		end

		def post_conditions
			result = {
				description: 'Creates a news item and returns the resource.',
				attributes: {
					title: {required: true, type: String, description: 'The title of the news item.'},
					category: {required: false, type: String, description: 'The category of the news item.'},
					imageid: {required: false, type: BSON::ObjectId, description: 'The file id of an image.'},
					language: {required: false, type: String, description: 'The language of the news item.'},
					timestamp: {required: false, type: DateTime, description: 'The timestamp of the news item.'},
					format_type: {required: false, type: String, description: 'The formatting type of the content, which could be \'ubb\' (default), \'html\' or \'plain\'.'},
					content: {required: true, type: RichText, description: 'The content of the item in the format.'},
				}
			}
			result[:attributes].merge(self.rights_conditions)
			result[:attributes].merge(self.tags_conditions)
			return result
		end

		def get_conditions
			{
				description: 'Returns a news item with the specified newsid',
			}
		end

		def put_conditions
			result =
				{
					description: 'Updates a news item with the given keys.',
					attributes: self.post_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the news items'
			}
		end

	end

	API.register_resource(NewsResource.new('news', '', '[newsid]'))
	API.register_resource(TagsResource.new('news', '[newsid]/tags', NewsItem))

end