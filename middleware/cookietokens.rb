module Mojura

  class CookieTokens

    def initialize(app)
      @app = app
    end

    def call(env)
			env['rack.request.cookie_hash'] ||= {}
      status, headers, body = @app.call(env)
      if headers.include?('X-persist-token')
				Rack::Utils.set_cookie_header!(headers, 'username', {value: headers['X-persist-username'], path: '/', expires: Time.now + (30 * 24*60*60)})
				Rack::Utils.set_cookie_header!(headers, 'token', {value: headers['X-persist-token'], path: '/', expires: Time.now + (30 * 24*60*60)})
 				headers.delete('X-test')
 				headers.delete('X-persist-username')
 				headers.delete('X-persist-token')
      end
      [status, headers, body]
    end
  end
end