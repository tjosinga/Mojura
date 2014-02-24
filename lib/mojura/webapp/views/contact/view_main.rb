module MojuraWebApp

	class ContactView < BaseView

		def initialize(options = {}, data = {})
			super
		end

	end

	WebApp.register_view('contact', ContactView)


end