require 'webapp/mojura/lib/settings'

module MojuraWebApp

	class UsersView < BaseView

		def initialize(options = {})
			params = WebApp.page.request_params
			data = {}
			data[:users_page_url] = Settings.get_s(:default_page_users, :core, 'users')
			data[:show_extensive] = !params[:userid].to_s.empty?
			data[:show_avatars] = !data[:show_extensive]
			data[:show_email] = WebApp.current_user.logged_in? &&
													((WebApp.current_user.id == params[:userid]) || Settings.get_b(:show_email, :users, false))
 			command = (data[:show_extensive]) ? "users/#{params[:userid]}" : 'users'
      data.merge!(WebApp.api_call(command))

			if (data[:show_extensive] && data[:rights][:update])
				WebApp.page.include_template_file('template-edit-userinfo', 'webapp/views/users/view_edit_userinfo.mustache')
				WebApp.page.include_template_file('template-edit-avatar', 'webapp/views/users/view_edit_avatar.mustache')
				WebApp.page.include_template_file('template-edit-password', 'webapp/views/users/view_edit_password.mustache')
				WebApp.page.include_template_file('template-edit-groups', 'webapp/views/users/view_edit_groups.mustache')
				if data[:rights][:delete]
					WebApp.page.include_template_file('template-deactivate-user', 'webapp/views/users/view_deactivate_user.mustache')
				end
				WebApp.page.include_script_link('ext/crypto-js/md5.min.js')
				WebApp.page.include_locale(:system)
				WebApp.page.include_locale(:users)
			end

			super(options, data)
		end

		WebApp.register_view('users', UsersView)

	end


end