module MojuraWebApp

	class SetupView < BaseView

		def initialize(options = {})
			data = WebApp.api_call('setup')
			super(options, data)
			WebApp.page.include_script_link('ext/crypto-js/md5.min.js')
		end

	end

	WebApp.register_view('setup', SetupView, :in_pages => false)

end