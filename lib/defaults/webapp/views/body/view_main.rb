module MojuraWebApp

	class BodyView < BaseBodyView

		def initialize(options = {})
			super(options)
		end

	end

	WebApp.register_view('body', BodyView, :in_pages => false)

end