require 'webapp/mojura/lib/baseview'

module MojuraWebApp

	class PageEditView < BaseView

		def initialize(options = {})
			data = {}
			options ||= {}
			if self.may_render
				data[:pageid] = WebApp.page.pageid
				data[:title] = WebApp.page.data[:title]
				data[:views] = WebApp.get_views
				data[:col_spans] = (1..12).to_a.map { |i| {index: i, title: i} }
				data[:col_spans].reverse!
				data[:col_offsets] = (0..11).to_a.map { |i| {index: i, title: i} }
				data[:row_offsets] = (0..10).to_a.map { |i| {index: i, title: i} }
				data[:templates] = WebApp.api_call('pages/templates', {col_count: 12})
				data[:templates].each { |template| template[:title] = Locale.str(:view_template_names, template[:templateid]) }
				options[:uses_editor] = true
				WebApp.page.include_script_link('mojura/js/pageeditor.js')
				WebApp.page.include_script('if (document.location.hash == \'#editing\') jQuery(\'#toggle_edit_page\').click()')
				WebApp.page.include_script_link('ext/mustache/mustache.min.js')
			end
			super(options, data)
		end

		def may_render
			WebApp.page.data[:rights][:allowed][:update] rescue false
		end

		def render
			return '' if (!self.may_render)
			return super
		end

	end

end