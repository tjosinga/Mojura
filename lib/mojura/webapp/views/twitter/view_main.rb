require 'webapp/mojura/lib/settings'

module MojuraWebApp

	class TwitterView < BaseView

		def initialize(options = {})
			WebApp.page.include_script_link('views/twitter/twitter_api.js')
			WebApp.log.debug(JSON.pretty_generate(options))
			data = options
			data[:max_tweets] ||= 5
			data[:show_avatars] ||= false
			data[:show_time] ||= false
			data[:show_actions] ||= false
			super({}, data)
		end

		def render
			@data[:render_id] = SecureRandom.hex
			super
		end


	end

	WebApp.register_view('twitter', TwitterView)

end