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
				locale = WebApp.locale
				unless @@views.has_key?(WebApp.locale)
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

				views = []
				WebApp.get_views.each { | view |
					views.push({view_id: view[:view_id], min_col_span: view[:min_col_span], title: Locale.str(view[:view_id], :view_title)});
					views.sort! { | x, y | x[:title] <=> y[:title] }
				}
				WebApp.page.include_script("PageEditor.init('#{WebApp.page.pageid}', #{JSON.generate(views)})")
				WebApp.page.include_script('if (document.location.hash == \'#editing\') jQuery(\'#toggle_edit_page\').click()')
				WebApp.page.include_script_link('ext/jquery/jquery-sortable.min.js')
				WebApp.page.include_locale(:system)
				WebApp.page.include_template_file('template-pageview-addedit-page', 'webapp/mojura/modals/pageedit_addedit_page.mustache')
				WebApp.page.include_template_file('template-pageview-delete-page', 'webapp/mojura/modals/pageedit_delete_page.mustache')
				WebApp.page.include_template_file('template-pageview-edit-view', 'webapp/mojura/modals/pageedit_edit_view.mustache')
				WebApp.page.include_template_file('template-pageview-delete-view', 'webapp/mojura/modals/pageedit_delete_view.mustache')
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