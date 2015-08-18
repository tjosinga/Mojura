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
			use_locale = !params[:use_locale].is_a?(FalseClass) && API.multilingual?
			if !path.empty?
				result = PageTree.new.nodes_of_path(params[:path])
				if (params[:auto_set_locale])
					locale = API.locale
					result.reverse_each { | page |
						if !page[:locales].nil?
							if page[:locales].size == 1
								locale = page[:locales][0]
								break
							elsif page == result.first
								locale = page[:locales][0]
							end
						end
					}
					API.locale = locale
				end
			elsif (!params[:path_pageid].to_s.empty?)
				result = PageTree.new.parents_of_node(params[:path_pageid]) || []
				result << Page.new(params[:path_pageid]).to_h
			else
				menu_only = params[:menu_only]
				depth = menu_only ? 2 : 0
				depth = params[:depth].to_i if params.has_key?(:depth)
				depth = 100 if depth <= 0
				root_id = nil
				if use_locale
					root_id = Settings.get_s("root_pageid_#{API.locale}".to_sym)
					root_id = nil if root_id.empty?
				end
				result = PageTree.new(menu_only, use_locale).to_a(depth, root_id)
			end
			return result
		end

		def post(params)
			page = Page.new
			raise NoRightsException unless AccessControl.has_rights?(:create, page)
			if (API.multilingual? && params[:parentid].to_s.empty?)
				pid = Settings.get_s("root_pageid_#{API.locale}".to_sym)
				params[:parentid] = pid.empty? ? nil : BSON::ObjectId(pid)
			end
			page.load_from_hash(params).save_to_db
			check_settings(params, page)
			return page.to_h
		end

		def get(params)
			page = Page.new(params[:ids][0])
			raise NoRightsException unless AccessControl.has_rights?(:read, page)
			return page.to_h
		end

		def put(params)
			page = Page.new(params[:ids][0])
			raise NoRightsException unless AccessControl.has_rights?(:update, page)
			if (!params[:parentid].nil?) && (params[:parentid].to_s.empty?) && (API.multilingual?)
				pid = Settings.get_s("root_pageid_#{API.locale}".to_sym)
				params[:parentid] = pid.empty? ? nil : BSON::ObjectId(pid)
			end
			page.load_from_hash(params).save_to_db
			check_settings(params, page)
			return page.to_h
		end

		def check_settings(params, page)
			if (params[:is_home])
				setting = API.multilingual? ? "default_pageid_#{API.locale}".to_sym : :default_pageid
				Settings.set(setting, page.id)
			end
			Settings.set("root_pageid_#{API.locale}".to_sym, page.id) if (params[:is_root] && API.multilingual?)
		end

		def delete(params)
			page = Page.new(params[:ids][0])
			raise NoRightsException unless AccessControl.has_rights?(:delete, page)
			page.delete_from_db
			return [:success => true]
		end

		def all_conditions
			{
				description: 'Returns a tree of all pages',
				attributes: {
					depth: {required: false, type: Integer, description: 'The depth of the returned tree. If not specified, the whole tree is returned.'},
					menu_only: {required: false, type: Boolean, description: 'If set to true, this will only return a tree of menu items.'},
					use_locale: {required: false, type: Boolean, description: 'If true checks if the page uses the current locale. False to return the pages regardless of the locale.'},
					path: {required: false, type: String, description: 'If a path (titles seperated with the \'/\' symbol) is given, a list of all pages on that path are returned. The last page will be returned fully. Returns an 404 error if the page does not exists. Each title should be \'urlencoded\' twice.'},
					auto_set_locale: {required: false, type: Boolean, description: 'Set to true to set the sessions locale automatically to the page or nearest page, based on the given path attribute.'},
					path_pageid: {required: false, type: String, description: 'If a path_pageid is given, a list of all pages on the path of the given page are returned. Returns an 404 error if the page does not exists. Is skipped when using path.'}
				}
			}
		end

		def post_conditions
			result = {
				description: 'Creates a page and returns the object.',
				attributes: {
					parentid: {required: false, type: BSON::ObjectId, description: 'The ID of the parent page. If none is given, it\'s placed in the root of the tree.'},
					title: {required: true, type: String, description: 'The title of the page, preferably unique.'},
					in_menu: {required: false, type: Boolean, description: 'A key-value hash of settings. Default is true.'},
					menu_title: {required: false, type: String, description: 'An alternative title which is used in the menu\'s.'},
					orderid: {required: false, type: Integer, description: 'An id to specify the sorting order.'},
					is_home: {required: false, type: Boolean, description: 'True if this page should be set as the home page. On multilingual sites, it is set as the home page for the current locale.'},
					is_locale_root: {required: false, type: Boolean, description: 'True if this page should be set as a root page for a specific locale. This requires to set a single locale as well. Default is false.'},
				}
			}
			result[:attributes].merge(self.rights_conditions)
			result[:attributes].merge(self.tags_conditions)
			result[:attributes].merge(self.locales_conditions)
			return result
		end

		def get_conditions
			{
				description: 'Returns a page with the specified pageid'
			}
		end

		def put_conditions
			{
				description: 'Updates a page with the given keys.',
				attributes: self.post_conditions[:attributes].each { |_, v| v[:required] = false }
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