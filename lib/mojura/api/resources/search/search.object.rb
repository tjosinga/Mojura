require 'api/lib/dbobjects_rights'

module MojuraAPI

	module SearchIndex

		include DbObjectsRights
		extend self

		KEYWORDS_PATTERN = /[\w@\d]+/

		#noinspection RubyStringKeysInHashInspection
		def set(id, category, title, description, api_url, weighted_keywords = {}, rights = {}, locales = [])
			@collection ||= MongoDb.collection(:search_index)
			keywords = []
			weighted_keywords.each { | keyword, weight |
				keywords.push({keyword: keyword.normalize.downcase, weight: weight})
			}
			title = description if title.to_s.empty?
			# Forces correct rights
			values = {
				id: id.to_s,
				locales: locales,
				title: title.to_s.truncate(100),
				description: description.to_s.truncate(160),
				category: category,
				api_url: api_url,
			  keywords: keywords,
				rights: rights[:rights] || DbObjectRights.int_to_rights_hash(0x7044),
				userids: rights[:userids] || [],
				groupids: rights[:groupids] || []
			}
			@collection.create_index({'keywords.keyword' => 1})
			@collection.create_index({'category' => 1})
			@collection.update({'id' => id.to_s}, values, {upsert: true})
		end

		def unset(id)
			@collection ||= MongoDb.collection(:search_index)
			@collection.remove({'id' => id})
		end

		#noinspection RubyStringKeysInHashInspection
		def search(keyword_string, category, options = {})
			@collection ||= MongoDb.collection(:search_index)
			options[:limit] ||= 25
			options[:skip] ||= 0

			regex = keyword_string.normalize.downcase.scan(KEYWORDS_PATTERN).join('|')
			first_matches = []
			first_matches.push({'category' => category}) unless category.to_s.empty?
			unless options[:check_locale].is_a?(FalseClass)
				first_matches.push({'$or' => [
						{'locales' => []},
						{'locales' => {'$in' => [API.locale]}}
				]})
			end
			first_matches.push({'keywords.keyword' => {'$regex' => /^(#{regex})/}})
			first_matches.push(self.get_rights_where(API.current_user)) unless API.current_user.administrator?

			pipeline = [
				# Selects only the documents containing these keywords (for performance), and where the user has right
				{'$match' => {'$and' => first_matches}},
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
				{'$sort' => {'score' => -1, 'title' => 1}},
				{'$skip' => options[:skip]},
				{'$limit' => options[:limit]}
			]
			result = @collection.aggregate(pipeline)
			result.each { | item | item.delete('_id') }
			return result
		end

	end

end