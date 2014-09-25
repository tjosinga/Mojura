require 'api/lib/restresource'

module MojuraAPI

	class PageViewResource < RestResource

		def name
			'Pageviews'
		end

		def description
			'Resource of views for a page. This is a core resource in Mojura.'
		end

		def extract_settings(params)
			result = {}
			params.each { |k, v|
				k = k.to_s
				if k.start_with?('setting_')
					key = k.gsub(/^setting_/, '')
					result[key.to_sym] = v
				end
			}
			return result
		end

		def uri_id_to_regexp(id_name)
			(id_name == 'viewids') ? "[\\d,]*\\d" : super
		end

		def all(params)
			page = Page.new(params[:ids][0])
			#TODO: check rights
			return page.views_to_h
		end

		def post(params)
			raise Exception.new if (params[:ids][0] == '0')
			page = Page.new(params[:ids][0])
			#TODO: check rights
			view = page.add_view(params[:parentid], params)
			page.save_to_db
			return page.view_to_h(view, view[:index], params[:parentid])
		end

		def get(params)
			raise Exception.new if (params[:ids][0] == '0')
			page = Page.new(params[:ids][0])
			#TODO: check rights
			ids = params[:ids][1].split(',')
			index = ids.pop
			path = ids.join(',')
			return page.view_to_h(page.get_view(params[:ids][1]), index, path)
		end

		def put(params)
			raise Exception.new if (params[:ids][0] == '0')
			page = Page.new(params[:ids][0])
			#TODO: check rights
			params[:settings] = self.extract_settings(params)
			view = page.update_view(params[:ids][1], params)
			page.save_to_db

			ids = params[:ids][1].split(',')
			index = ids.pop
			path = ids.join(',')

			index = params[:index] if params.include?(:index)
			path = params[:path] if params.include?(:path)
			return page.view_to_h(view, index, path)
		end

		def delete(params)
			raise Exception.new if (params[:ids][0] == '0')
			page = Page.new(params[:ids][0])
			page.delete_view(params[:ids][1])
			page.save_to_db
			return page.to_h
		end

		def all_conditions
			{
				description: 'Returns all views of the specified page. These are also visible when GET-ing a specific page.'
			}
		end

		def get_conditions
			{
				description: 'Returns a view of the specified page',
			}
		end

		def post_conditions
			{
				description: 'Updates a view of the specified page.',
				attributes: {
					parentid: {required: false, type: String, description: 'Comma separated list of the parent view.'},
					view: {required: false, type: String, description: 'The view of the corresponding page.'},
					content: {required: false, type: String, description: 'The textual content of a page.'},
					settings: {required: false, type: Hash, description: 'A key-value hash of settings. You can also use setting_[key]=[value].'},
					col_span: {required: false, type: Integer, description: 'The column span of the view. Default is the full available size.'},
					col_offset: {required: false, type: Integer, description: 'The left offset of the view. Default is an offset of zero.'},
					row_offset: {required: false, type: Integer, description: 'The top offset of the view. Default is an offset of zero.'},
					index: {required: false, type: String, description: 'The index of the view. An index of 0 places the view as first view within its parent.'}
				}
			}
		end

		def put_conditions
			{
				description: 'Updates a view of the specified page.',
				attributes: self.post_conditions[:attributes].each { |_, v| v[:required] = false }
			}
		end

		def delete_conditions
			{
				description: 'Deletes the page'
			}
		end

	end

	API.register_resource(PageViewResource.new('pages', '[pageid]/views/', '[pageid]/view/[viewids]'))

end