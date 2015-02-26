module MojuraWebApp

	class DataView < BaseView

		def initialize(options = {}, data = {})
			super(options, WebApp.api_call('data'))
			WebApp.page.include_template_file('template-data-table-body', 'webapp/views/data/view_table_body.mustache')
			WebApp.page.include_template_file('template-data-details', 'webapp/views/data/view_details.mustache')
			WebApp.page.include_script_link('ext/moment/moment-with-locales.min.js')
			WebApp.page.include_locale(:data)
		end

		def render(*args)
			if WebApp.current_user.administrator?
				return super
			else
				return render_no_rights
			end
		end

	end

	WebApp.register_view('data', DataView)


end