module MojuraWebApp

	class PollsView < BaseView

		def initialize(options = {}, data = {})
			options[:view_type] ||= 'list'

			api_params = (options[:view_type] == 'last_active') ? { filter: '(active:true)', pagesize: 1 } : {}
			data = WebApp.api_call('polls', api_params)
			data[:show_admin] = WebApp.current_user.logged_in?
			data[:show_active] = data[:show_admin] && (options[:view_type] == 'list')
			data[:polls] = data[:items]
			data[:polls].each { | poll | poll[:voteable] = false } if (options[:view_type] == 'list')

			super(options, data);

			WebApp.page.include_template_file('template-polls-results', 'webapp/views/polls/view_results.mustache')
			if WebApp.current_user.logged_in?
				WebApp.page.include_template_file('template-polls-addedit', 'webapp/views/polls/view_add_edit.mustache')
				WebApp.page.include_template_file('template-polls-delete', 'webapp/views/polls/view_delete.mustache')
			end
			WebApp.page.include_locale('polls')
		end

		WebApp.register_view('polls', PollsView)

	end

end