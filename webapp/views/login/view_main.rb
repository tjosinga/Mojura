module MojuraWebApp

	class LoginView < BaseView

		def initialize(options = {})
			if Settings.get(:use_external_js_libs, true)
				WebApp.page.include_script_link('http://crypto-js.googlecode.com/svn/tags/3.0.2/build/rollups/md5.js')
				WebApp.page.include_script_link('http://crypto-js.googlecode.com/svn/tags/3.0.2/build/rollups/pbkdf2.js')
			else
				WebApp.page.include_script_link('ext/crypto-js/md5.js')
				WebApp.page.include_script_link('ext/crypto-js/pbkdf2.js')
			end
			super(options, {})
		end

		def is_logged_in
			!WebApp.current_user.id.nil?
		end

	end

	WebApp.register_view('login', LoginView)

end