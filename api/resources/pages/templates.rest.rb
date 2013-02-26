require 'api/lib/restresource'

module MojuraAPI

	class PageTemplateResource < RestResource

		def name
			'Page Templates'
		end

		def description
			'Resource of templates for a page. This is a core resource in Mojura.'
		end

		def uri_id_to_regexp(id_name)
			(id_name == 'templateid') ? "\\w+" : super
		end

		def all(params)
			PageTemplates.get_templates((params[:col_count] || 0).to_i)
		end

		def get(params)
			page = Page.new
			page.view_to_a(page.new_view_from_template(params[:ids][0]))
		end

		def all_conditions
			{
				description: 'Returns all templates for pages.',
				attributes:  {
					col_count: {required: false, type: Integer, description: 'Returns all templates for a specific column count. If none or 0 is given, all templates are returned'}
				}
			}
		end

		def get_conditions
			{
				description: 'Returns a specific template for pages.',
			}
		end

	end

	API.register_resource(PageTemplateResource.new('pages', 'templates', 'template/[templateid]'))

end