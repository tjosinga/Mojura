require 'api/lib/dbobjects_rights'

module MojuraAPI

	module SearchIndex

		include DbObjectsRights
		extend self

		KEYWORDS_PATTERN = /[\w@\d]+/

		#noinspection RubyStringKeysInHashInspection
		def set(id, category, title, description, api_url, weighted_keywords = {}, rights = {})
			@collection ||= MongoDb.collection(:search_index)
			keywords = []
			weighted_keywords.each { | keyword, weight |
				keywords.push({keyword: keyword.normalize.downcase, weight: weight})
			}
			# Forces correct rights
			values = {
				id: id.to_s,
				title: title,
				description: description,
				category: category,
				api_url: api_url,
			  rights: rights,
			  keywords: keywords,
				right: rights[:right] || 0x7044,
				userids: rights[:userids] || [],
				groupids: rights[:groupids] || []
			}
			@collection.create_index({collection: 1})
			@collection.create_index({'keywords.keyword' => 1})
			@collection.update({'id' => id.to_s}, values, {upsert: true})
		end

		def unset(id)
			@collection ||= MongoDb.collection(:search_index)
			MongDb.collection(:search_index).remove({'id' => id})
		end

		#noinspection RubyStringKeysInHashInspection
		def search(keyword_string, options = {})
			@collection ||= MongoDb.collection(:search_index)
			options[:limit] ||= 25
			options[:skip] ||= 0

			regex = keyword_string.normalize.downcase.scan(KEYWORDS_PATTERN).join('|')
			first_match = {'keywords.keyword' => {'$regex' => /^(#{regex})/}}
			first_match = {'$and' => [first_match, self.get_rights_where(API.current_user)]} unless API.current_user.administrator?

			pipeline = [
				# Selects only the documents containing these keywords (for performance), and where the user has right
				{'$match' => first_match},
				# Break up the documents in subdocuments
				{'$unwind' => '$keywords'},
				# Select only the subdocument with the keywords
				{'$match' => {'keywords.keyword' => {'$regex' => /^(#{regex})/}}},
				# Group all subdocuments into documents, adding a score value
				{'$group' => {
					'_id' => '$id',
					'id' => {'$first' => '$id'},
					'title' => {'$first' => '$title'},
					'category' => {'$first' => '$category'},
					'api_url' => {'$first' => '$api_url'},
					'description' => {'$first' => '$description'},
					'score' => {'$sum' => '$keywords.weight'}}},
				## Sort on score, ascending
				{'$sort' => {'score' => -1}},
				{'$skip' => options[:skip]},
				{'$limit' => options[:limit]}
			]
			result = @collection.aggregate(pipeline)
			result.each { | item | item.delete('_id') }
			return result
		end

	end

end