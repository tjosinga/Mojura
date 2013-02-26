require 'api/lib/restresource'
require 'api/resources/pages/pages.objects'
require 'api/resources/pages/views.rest'
require 'api/resources/pages/templates.rest'

module MojuraAPI

	class PageResource < RestResource

		def name
			'Pages'
		end

		def description
			'Resource of pages, which is a core object in Mojura.'
		end

		def all(params)
			path = (params.has_key?(:path)) ? params[:path] : ''
			if path != ''
#	    	full = (params.has_key?(:path)) ? params[:path] : ''
				result = PageTree.new.nodes_of_path(params[:path])
			else
				depth     = (params.has_key?(:depth)) ? params[:depth].to_i : 2
				menu_only = (params[:menu_only] == 'true')
				result    = PageTree.new(menu_only).to_a(depth)
			end
			return result
		end

		def put(params)
			#TODO: Check rights
			Page.new.load_from_hash(params).save_to_db.to_a
		end

		def get(params)
			page = Page.new(params[:ids][0])
			#TODO: Check rights
			return page.to_a
		end

		def post(params)
			page = Page.new(params[:ids][0])
			#TODO: Check rights
			page.load_from_hash(params)
			return page.save_to_db.to_a
		end

		def delete(params)
			page = Page.new(params[:ids][0])
			#TODO: Check rights
			page.delete_from_db
			return [:success => true]
		end

		def all_conditions
			{
				description: 'Returns a tree of all pages',
				attributes:  {
					depth:     {required: false, type: Integer, description: 'The depth of the returned tree. If not specified, the whole tree is returned.'},
					menu_only: {required: false, type: Boolean, description: 'If set to true, this will only return a tree of menu items.'},
					path:      {required: false, type: String, description: 'If a path (titles seperated with the \'/\' symbol) is given, a list of all pages on that path are returned. The last page will be returned fully. Returns an 404 error if the page does not exists. Each title should be \'urlencoded\' twice.'},
				}
			}
		end

		def put_conditions
			result = {
				description: 'Creates a page and returns the object.',
				attributes:  {
					parentid:   {required: false, type: BSON::ObjectId, description: 'The ID of the parent page. If none is given, it\'s placed in the root of the tree.'},
					title:      {required: true, type: String, description: 'The title of the page, preferably unique.'},
					in_menu:    {required: false, type: Boolean, description: 'A key-value hash of settings. Default is true.'},
					menu_title: {required: false, type: String, description: 'An alternative title which is used in the menu\'s.'},
				}
			}
			result[:attributes].merge(self.rights_conditions)
			result[:attributes].merge(self.tags_conditions)
			return result
		end

		def get_conditions
			{
				description: 'Returns a page with the specified pageid'
			}
		end

		def post_conditions
			{
				description: 'Updates a page with the given keys.',
				attributes:  self.put_conditions[:attributes].each { |_, v| v[:required] = false }
			}
		end

		def delete_conditions
			{
				description: 'Deletes the page'
			}
		end

	end

	API.register_resource(PageResource.new('pages', '', '[pageid]'))

end