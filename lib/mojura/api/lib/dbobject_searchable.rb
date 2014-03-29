# encoding: utf-8
require 'api/resources/search/search.object'

module MojuraAPI

	# Aggregation example:
	# db.users.aggregate(
	#   {$project: {"_id": 1, "searchable_keywords": 1}},
	#   {$unwind: "$searchable_keywords"},
	#   {$match: {"searchable_keywords.keyword": {$in: ["osinga", "taco"]}}},
	#   {$group: {"_id": "$_id", "score": {$sum: "$searchable_keywords.weight"}}},
	#   {$sort: {"score": -1}});


	module DbObjectSearchable

		def regenerate_for_search_index?
			@fields.each { | field, options |
				return true if (options[:searchable]) && (options[:changed])
			}
			if (self.class.include?(DbObjectRights))
				return @fields[:right][:changed] || @fields[:userids][:changed] || @fields[:groupids][:changed]
			end
			return false
		end

		def get_weighted_keywords
			result = {}
			@fields.each { | field, options |
				if (options[:searchable])
					str = get_searchable_string(field)
					str.scan(SearchIndex::KEYWORDS_PATTERN).each { | keyword |
						result[keyword] ||= 0
						result[keyword] += options[:searchable_weight]
					}
				end
			}
			return result
		end

		def get_search_index_title_and_description
			[name || title, '']
		end

		def get_searchable_string(field)
			options = {}
			options[:markup] = @fields[(field.to_s + '_markup').to_sym][:value] if (@fields[field][:type] == 'RichText')
			return typed_value_to_searchable_string(@fields[field][:type], @fields[field][:value], options)
		end

		def typed_value_to_searchable_string(type, value, options = {})
			if (type === RichText)
				if (options[:markup] == :ubb)
					value = UBBParser.strip_ubb(value)
				else
					value = Sanitize.clean(RichText.new(value).to_html)
				end
			end
			return value.to_s
		end

	end

end