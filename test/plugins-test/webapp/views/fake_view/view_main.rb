module MojuraWebApp

	class FakeView < BaseView

		def initialize(options = {})
			super(options, {})
		end

	end

	WebApp.register_view('fake_view', FakeView)

end