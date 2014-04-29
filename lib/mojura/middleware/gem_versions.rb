require 'rack'
require 'rubygems'

module Mojura

	# Preferably your webserver serves files using X-Sendfile (also see http://wiki.nginx.org/XSendfile). However, in some
	# cases the server doesn't support that. In that case use this middleware by including it in the config.ru file.
	class GemVersions

		@versions

		def initialize(app)
			@app = app
			@versions = {}
			%w(mojura kvparser ubbparser).each { | gem |
				version = `gem spec #{gem} version`[/(\d+.\d+.\d+)/]
				@versions[gem] = version unless version.nil?
			}
		end

		def call(env)
			status, headers, body = @app.call(env)
			headers.merge!(@versions)
			return [status, headers, body]
		end

	end

end