require 'api/lib/restresource'
require 'api/resources/search/search.object'

module MojuraAPI

	class SearchResource < RestResource

		def name
			'Search'
		end

		def description
			'Resource for searching items. It supports weighted results, but does not support stemming.'
		end

		def all(params)
			params[:pagesize] ||= 25
			result = SearchIndex.search(params[:keywords])
			return result
		end

		def all_conditions
			result = {
				description: 'Returns a list of items. Use pagination and filtering to make selections.',
				attributes: {
					keywords: {required: true, type: String, description: 'The keywords to search for.'},
					category: {required: false, type: String, description: 'The category to search in. If none given'},
				}
			}
			result[:attributes].merge(self.filter_conditions)
			return result
		end

	end

	API.register_resource(SearchResource.new('search', '', ''))

end