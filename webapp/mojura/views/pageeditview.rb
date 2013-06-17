require 'webapp/mojura/lib/baseview'

module MojuraWebApp

	#noinspection RubyClassVariableUsageInspection
	class PageEditView < BaseView

		@@views = {}

		def initialize(options = {})
			data = {}
			options ||= {}
			if self.may_render
				data[:pageid] = WebApp.page.pageid
				data[:title] = WebApp.page.data[:title]
				locale = WebApp.page.locale
				unless @@views.has_key?(WebApp.page.locale)
					@@views[locale] = []
					(WebApp.get_views || []).each { | obj |
						obj[:title] = Locale.str(obj[:view_id], :view_title)
						@@views[locale].push(obj)
					}
					@@views[locale].sort! { | a, b | a[:title] <=> b[:title] }
				end
				data[:views] = @@views[locale]
				data[:col_spans] = (1..12).to_a.map { |i| {index: i, title: i} }
				data[:col_spans].reverse!
				data[:col_offsets] = (0..11).to_a.map { |i| {index: i, title: i} }
				data[:row_offsets] = (0..10).to_a.map { |i| {index: i, title: i} }
				data[:templates] = WebApp.api_call('pages/templates', {col_count: 12})
				data[:templates].each { |template| template[:title] = Locale.str(:view_template_names, template[:templateid]) }

				options[:uses_editor] = true
				WebApp.page.include_script_link('mojura/js/pageeditor.js')

				WebApp.page.include_script('if (document.location.hash == \'#editing\') jQuery(\'#toggle_edit_page\').click()')
				WebApp.page.include_locale(:system)
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