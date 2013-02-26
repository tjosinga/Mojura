require 'securerandom'
require 'rack'

module Mojura

	class Gatekeeper

		def initialize(app)
			@app = app
		end

		def call(env)
			req = Rack::Request.new(env)

			port     = env['SERVER_PORT'].to_i
			port_str = ((port != 80) && (port != 443)) ? ':' + port.to_s : ''

			env['rack.session']             ||= {}
			env['rack.request.cookie_hash'] ||= {}
			env['is_api_call']              = (env['SERVER_NAME'][0..3].downcase == 'api.')
			env['api_url']                  = env['rack.url_scheme'].to_s + "://#{env['SERVER_NAME']}#{port_str}/"

			env['api_url'] += '__api__/' if (!env['is_api_call'])

			if (!env['is_api_call']) && (env['PATH_INFO'].match(/^\/__api__/))
				env['is_api_call'] = true
				env['PATH_INFO'].gsub!(/^\/__api__/, '')
				env['REQUEST_URI'].gsub!(/^\/__api__/, '')

				# Check for the dynamic web api key
				wak_cookie  = req.cookies['web_api_key']
				wak_session = env['rack.session']['web_api_key']
				return [403, {}, [{error: 'Unauthorized API access'}]] if (wak_cookie.nil?) || (wak_cookie != wak_session)
			end

			status, headers, body = @app.call(env)

			if (status == 200) && (!env['is_api_call']) &&
				((!req.cookies.has_key?('web_api_key') || (!env['rack.session'].include?('web_api_key'))))

				env['rack.session']['web_api_key'] = 'web-' + SecureRandom.hex(16)
				Rack::Utils.set_cookie_header!(headers, 'web_api_key', {value: env['rack.session']['web_api_key'], path: '/'})
			end

			return [status, headers, body]
		end

	end
end