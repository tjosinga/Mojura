require 'rack'

module Mojura

	# Preferably your webserver serves files using X-Sendfile (also see http://wiki.nginx.org/XSendfile). However, in some
	# cases the server doesn't support that. In that case use this middleware by including it in the config.ru file.
	class SendFiles

		def initialize(app)
			@app = app
		end

		def call(env)
			status, headers, body = @app.call(env)
			return [status, headers, body] unless headers.include?('X-Accel-Redirect')
			filename = body[0][:to_path] || body[0]['to_path']
			return [404, {}, []] unless File.exists?(filename)
			return [status, headers, [File.binread(filename)]]
		end

	end

end