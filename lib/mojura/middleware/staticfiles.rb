require 'rack'

module Mojura

	# Static files should be server directly. However in development, using webrick, this middleware serves static files,
	# excluding Ruby files.
	# Configure your webserver to directly serve all static files in /webapp, excluding all ruby files.
	class StaticFiles

		def initialize(app)
			@app = app
		end

		def call(env)
			filename = Mojura.filename('webapp/' + env['PATH_INFO'].to_s).to_s
			if File.file?(filename) && (File.extname(filename) != '.rb')
				headers = {'Content-Type' => Rack::Mime.mime_type(File.extname(filename))}
				headers['X-Accel-Redirect'] = filename
				return [200, headers, [{'to_path' => filename}]]
			end
			@app.call(env)
		end

	end

end