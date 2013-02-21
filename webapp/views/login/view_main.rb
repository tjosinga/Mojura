module MojuraWebApp

	class LoginView < BaseView

		def render
			WebApp.page.include_script_link('http://crypto-js.googlecode.com/svn/tags/3.0.2/build/rollups/md5.js')
			WebApp.page.include_script_link('http://crypto-js.googlecode.com/svn/tags/3.0.2/build/rollups/pbkdf2.js')
			super
		end

		def is_logged_in
			!WebApp.current_user.id.nil?
		end

	end

	WebApp.register_view('login', LoginView)

end