module MojuraWebApp

	class LoginView < BaseView

		def initialize(options = {})
			WebApp.page.include_script_link('ext/crypto-js/md5.min.js')
			WebApp.page.include_script_link('ext/crypto-js/pbkdf2.min.js')
			WebApp.page.include_locale(:login)
			super(options, {})
		end

		def is_logged_in
			!WebApp.current_user.id.nil?
		end

	end

	WebApp.register_view('login', LoginView)

end