module MojuraWebApp

	class PollsView < BaseView

		def initialize(options = {}, data = {})
			WebApp.page.include_template_file('template-polls-results', 'webapp/views/polls/view_results.mustache')
			if WebApp.current_user.logged_in?
				#WebApp.page.include_template_file('template-polls-addedit', 'webapp/views/polls/view_add_edit.mustache')
				#WebApp.page.include_template_file('template-polls-delete', 'webapp/views/polls/view_delete.mustache')
			end
			data = WebApp.api_call('polls')
			data[:polls] = data[:items]
			super(options, data);
		end

		WebApp.register_view('polls', PollsView)

	end


end