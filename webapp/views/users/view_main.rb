module MojuraWebApp

	class UsersView < BaseView

		def initialize(options = {})
			options[:view] ||= 'thumbs'
			options[:col_span] ||= 2

			api_call = (options[:api_call] || 'users')
			api_options = {}
			data = WebApp.api_call(api_call, api_options)

			data[:span] = "span#{options[:col_span]}"
			data[:size] = ((options[:col_span] * 70) + ((options[:col_span] - 1) * 30)).to_i

			profile_url = (options[:profile_url] || 'profile/?userid=[userid]')
			data[:items].each { |item|
				item[:web_url] = profile_url.gsub(/\[userid\]/, item[:id])
				item[:thumb_name] = (options[:col_span] == 1) ? item[:firstname] : item[:fullname]
			}
			super(options, data)
		end

		def render
			super
		end

		def is_list_view
			@options[:view] == 'list'
		end

		def is_thumbs_view
			@options[:view] == 'thumbs'
		end

		WebApp.register_view('users', UsersView)

	end

end