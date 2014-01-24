module MojuraWebApp

	class EventsView < BaseView

		def initialize(options = {}, data = {})
			options[:view_type] ||= 'list'
			options[:view_range] ||= 'week'

			data = {}
			data[:type] = options[:view_type] || 'list'
			data[:range] = options[:view_range] || 'week'
			super(options, data);

			WebApp.page.include_locale('system')
			WebApp.page.include_script_link('ext/moment/moment-with-langs.js')
			WebApp.page.include_template_file('template-events', 'webapp/views/events/view_events.mustache')
			if WebApp.current_user.logged_in?
				#WebApp.page.include_template_file('template-events-addedit', 'webapp/views/events/view_add_edit.mustache')
				#WebApp.page.include_template_file('template-events-delete', 'webapp/views/events/view_delete.mustache')
				WebApp.page.include_locale('events')
			end
		end

		WebApp.register_view('events', EventsView)

	end


end